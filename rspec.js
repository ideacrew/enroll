const { spawn } = require('child_process');

const myArgs = process.argv.slice(2);

process.env.RAILS_ENV = 'test';

const ls = spawn('parallel_rspec', [...myArgs]);

ls.stdout.on('data', (data) => {
  // console.log(data.toString());
});

ls.stderr.on('data', (data) => {
  console.log(`stderr: ${data}`);
});

ls.on('error', (error) => {
  console.log(`error: ${error.message}`);
});

ls.on('close', (code) => {
  console.log(`child process exited with code ${code}`);
});
