package me.jxl.kiosk_satellite.sendspin.latency

/**
 * Source that most recently wrote the effective static delay.
 *
 * - [NONE]: no source has written; effective delay is 0
 * - [AUTO]: [OutputLatencyEstimator] converged successfully
 * - [USER]: user's settings slider
 * - [SERVER]: server-pushed `client/sync_offset`
 */
enum class StaticDelaySource { NONE, AUTO, USER, SERVER }
