import { check } from 'k6';

export function checkResponse(response, checkName) {
  const success = check(response, {
    [checkName]: (r) => r.status === 200 || r.status === 201,
  });

  if (!success) {
    console.error(`Failed check: ${checkName}. Status: ${response.status}. Body: ${response.body}`);
  }
  return success;
}