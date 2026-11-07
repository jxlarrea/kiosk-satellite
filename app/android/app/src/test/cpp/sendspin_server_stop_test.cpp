// Standalone regression for the Sendspin server closing its listening socket
// more than once. SendspinWsServer::stop() calls ix::WebSocketServer::stop()
// and then destroys the server, and the destructor stops it again. If the
// second stop closes the fd number again, it closes whatever was opened on
// that number in between. In the app that was a Java FileInputStream, and
// fdsan aborted the process. listen() closes its socket the same way when the
// port is taken, before the server is destroyed. Build this target explicitly
// and run it on Android: it exits 0 when every file opened on a closed server
// fd survives.
#include <dirent.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <utility>

#include "ixwebsocket/IXNetSystem.h"
#include "ixwebsocket/IXWebSocketServer.h"

namespace {

constexpr int kPort = 18928;
constexpr int kRounds = 20;

// fdsan is API 29 and the app builds for 24, so look it up at run time.
using ExchangeTag = void (*)(int, uint64_t, uint64_t);
using CloseWithTag = int (*)(int, uint64_t);
using SetLevel = int (*)(int);
constexpr int kFdsanFatal = 3;  // ANDROID_FDSAN_ERROR_LEVEL_FATAL
// The tag a Java FileInputStream puts on its fd: owner type 5 in the top byte.
constexpr uint64_t kFileInputStreamTag = (uint64_t{5} << 56) | 0x0c64a08a;

ExchangeTag exchangeTag = nullptr;
CloseWithTag closeWithTag = nullptr;

// The listening socket is the only socket in this process that accepts.
int findListeningFd() {
  DIR* dir = opendir("/proc/self/fd");
  if (dir == nullptr) return -1;
  int found = -1;
  while (dirent* entry = readdir(dir)) {
    const int fd = atoi(entry->d_name);
    if (fd <= 2) continue;
    int accepting = 0;
    socklen_t length = sizeof(accepting);
    if (getsockopt(fd, SOL_SOCKET, SO_ACCEPTCONN, &accepting, &length) == 0 &&
        accepting != 0) {
      found = fd;
      break;
    }
  }
  closedir(dir);
  return found;
}

// Opens a file on the lowest free fd, tagged like a FileInputStream.
int openTaggedFile() {
  const int fd = open("/proc/self/stat", O_RDONLY | O_CLOEXEC);
  if (fd >= 0 && exchangeTag != nullptr) exchangeTag(fd, 0, kFileInputStreamTag);
  return fd;
}

void closeTaggedFile(int fd) {
  if (closeWithTag != nullptr) {
    closeWithTag(fd, kFileInputStreamTag);
  } else {
    close(fd);
  }
}

// A listening socket on the port, so the server's bind fails.
int holdPort(int port) {
  const int fd = socket(AF_INET, SOCK_STREAM, 0);
  sockaddr_in address{};
  address.sin_family = AF_INET;
  address.sin_port = htons(port);
  address.sin_addr.s_addr = htonl(INADDR_ANY);
  if (fd < 0 || bind(fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) != 0 ||
      ::listen(fd, 1) != 0) {
    if (fd >= 0) close(fd);
    return -1;
  }
  return fd;
}

std::unique_ptr<ix::WebSocketServer> makeServer(int port) {
  auto server = std::make_unique<ix::WebSocketServer>(
      port, "0.0.0.0", ix::SocketServer::kDefaultTcpBacklog, 1, 3);
  server->setOnConnectionCallback(
      [](const std::weak_ptr<ix::WebSocket>&,
         const std::shared_ptr<ix::ConnectionState>&) {});
  return server;
}

// 0 when the file survived, 1 when the server closed it, 2 when the round
// could not put the file on the server's fd.
int finishRound(const char* name, int round, int serverFd, int fileFd,
                std::unique_ptr<ix::WebSocketServer> server) {
  if (fileFd != serverFd) {
    std::fprintf(stderr, "%s round %d: file on fd %d, server was on fd %d\n",
                 name, round, fileFd, serverFd);
    if (fileFd >= 0) closeTaggedFile(fileFd);
    return 2;
  }
  server.reset();
  const bool alive = fcntl(fileFd, F_GETFD) != -1;
  if (alive) closeTaggedFile(fileFd);
  std::printf("%s round %d: server fd %d, file opened on it before the server "
              "was destroyed: %s\n",
              name, round, serverFd, alive ? "still open" : "CLOSED by the server");
  return alive ? 0 : 1;
}

// What SendspinWsServer::stop() does: stop() and then destroy the server,
// whose destructor stops it again.
int runStopRound(int round) {
  auto server = makeServer(kPort);
  const auto listened = server->listen();
  if (!listened.first) {
    std::fprintf(stderr, "stop round %d: listen failed: %s\n", round,
                 listened.second.c_str());
    return 2;
  }
  server->start();
  const int serverFd = findListeningFd();
  server->stop();
  // The lowest free number goes to the next open, which is the one stop()
  // just freed.
  const int fileFd = openTaggedFile();
  return finishRound("stop", round, serverFd, fileFd, std::move(server));
}

// What SendspinWsServer::start() does when the port is taken: listen()
// fails and closes its socket, and the server is destroyed.
int runBindFailureRound(int round) {
  const int held = holdPort(kPort + 1);
  if (held < 0) {
    std::fprintf(stderr, "bind round %d: cannot hold port %d\n", round, kPort + 1);
    return 2;
  }
  auto server = makeServer(kPort + 1);
  const auto listened = server->listen();
  int result = 2;
  if (listened.first) {
    std::fprintf(stderr, "bind round %d: listen did not fail\n", round);
  } else {
    // listen() opens its select interrupt pipe, which stays open, then its
    // socket on the lowest free number. That number is the lowest free one
    // again once listen() closes the socket, so the file gets it.
    const int fileFd = openTaggedFile();
    result = finishRound("bind", round, fileFd, fileFd, std::move(server));
  }
  close(held);
  return result;
}

}  // namespace

int main(int argc, char** argv) {
  // --no-fdsan reports the stray close instead of aborting on it.
  const bool fdsan = !(argc > 1 && std::strcmp(argv[1], "--no-fdsan") == 0);
  if (fdsan) {
    void* libc = dlopen("libc.so", RTLD_NOW);
    exchangeTag = reinterpret_cast<ExchangeTag>(
        dlsym(libc, "android_fdsan_exchange_owner_tag"));
    closeWithTag = reinterpret_cast<CloseWithTag>(
        dlsym(libc, "android_fdsan_close_with_tag"));
    auto setLevel = reinterpret_cast<SetLevel>(
        dlsym(libc, "android_fdsan_set_error_level"));
    if (exchangeTag == nullptr || closeWithTag == nullptr || setLevel == nullptr) {
      std::fprintf(stderr, "fdsan is not available on this device\n");
      return 2;
    }
    setLevel(kFdsanFatal);
  }

  ix::initNetSystem();
  int closed = 0;
  int skipped = 0;
  for (int round = 1; round <= kRounds; round++) {
    for (const int result : {runStopRound(round), runBindFailureRound(round)}) {
      if (result == 1) closed++;
      if (result == 2) skipped++;
    }
  }
  ix::uninitNetSystem();

  std::printf("%d of %d rounds closed the file, %d skipped\n", closed,
              2 * kRounds, skipped);
  if (closed > 0) return 1;
  return skipped > 0 ? 2 : 0;
}
