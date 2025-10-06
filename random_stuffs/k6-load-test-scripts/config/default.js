export const options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up to 10 VUs over 2 minutes
    { duration: '5m', target: 10 }, // Stay at 10 VUs for 5 minutes
    { duration: '2m', target: 0 },  // Ramp down to 0 VUs
  ],
};