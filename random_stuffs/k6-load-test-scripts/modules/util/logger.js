export function log(message) {
  console.log(`[INFO] ${message}`);
}
export function logError(message) {
  console.error(`[ERROR] ${message}`);
}
export function selectEnv() {
  return __ENV.K6_ENV || 'default';
}