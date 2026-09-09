import { cmd } from './core.js';

// Read only existing flags and Set.size. Full stats enumerate the shadow
// store, which is unnecessary for the Overview label on a slow panel.
export const filterStatusScript = '(function(){var S=window.__ksWs;'
  + 'return JSON.stringify(S?{enabled:S.enabled,built:S.built,'
  + 'allow:S.allow?S.allow.size:null}:null);})()';

let status = null, sampledAt = -Infinity, pending = null, revision = 0;

// Other health events can refresh Overview more often than its 30-second
// timer. Share in-flight reads and cache failures as well as successful reads.
export async function readFilterStatus(enabled) {
  if (!enabled) {
    revision++;
    status = null;
    sampledAt = -Infinity;
    pending = null;
    return null;
  }
  if (pending) return pending;
  if (Date.now() - sampledAt < 30000) return status;
  const ownRevision = ++revision;
  pending = cmd('evalJs', { code: filterStatusScript }, { timeoutMs: 2000 })
    .then((result) => {
      if (!result?.ok) return null;
      let value = JSON.parse(result.data);
      if (typeof value === 'string') value = JSON.parse(value);
      if (!value?.enabled) return null;
      if (Number.isInteger(value.allow) && value.allow >= 0) {
        return { unfiltered: false,
          label: `Watching ${value.allow} ${value.allow === 1 ? 'entity' : 'entities'}` };
      }
      return value.built && value.allow === null
        ? { unfiltered: true, label: 'Updates unfiltered' } : null;
    })
    .catch(() => null)
    .then((value) => {
      if (revision !== ownRevision) return null;
      status = value;
      sampledAt = Date.now();
      return status;
    })
    .finally(() => { if (revision === ownRevision) pending = null; });
  return pending;
}
