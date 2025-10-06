export const commonThresholds = {
  // The rate of failed requests (non-2xx status codes) should be less than 1%
  http_req_failed: ['rate<0.01'],
  // 95% of requests must complete below 500ms
  http_req_duration: ['p(95)<500'],
};