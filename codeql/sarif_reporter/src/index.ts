import { Log } from 'sarif';
import { SummaryReporter } from './summary_reporter';

async function main() {
	let data = "";
	for await (const chunk of process.stdin) data += chunk;

	let log = <Log | null>JSON.parse(data);
  let sr = new SummaryReporter(log);

	process.exit(sr.execute());
}

main();
