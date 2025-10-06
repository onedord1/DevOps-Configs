const { spawn } = require('child_process');
const path = require('path');

// Set the environment for the test run
process.env.K6_ENV = 'staging';

// Load variables from .env file (if you have `dotenv` installed)
// For simplicity, we assume you will set them in your shell or have a .env file
// If you want to use .env, run `npm install dotenv` and uncomment the line below
require('dotenv').config();

const scenarioFile = path.join(__dirname, '../scenarios/userCreationFlow.js');
const k6Command = `k6 run ${scenarioFile}`;

console.log('--------------------------------------------------');
console.log(`🚀 Starting k6 test run...`);
console.log(`📂 Scenario: ${scenarioFile}`);
console.log(`🌍 Environment: ${process.env.K6_ENV}`);
console.log('--------------------------------------------------');

// Use spawn to run the command and see live output
const k6Process = spawn(k6Command, { shell: true, stdio: 'inherit' });

k6Process.on('close', (code) => {
  console.log('--------------------------------------------------');
  if (code === 0) {
    console.log('✅ k6 test run completed successfully.');
  } else {
    console.error(`❌ k6 test run failed with exit code ${code}.`);
  }
  console.log('--------------------------------------------------');
  process.exit(code);
});