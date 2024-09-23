import { Log } from 'sarif';
import { SummaryReporter } from './summary_reporter';
import { command, option, string, run } from 'cmd-ts';
import { IgnoreFile } from './ignore_file';

const ignoreFile = option({
	type: string,
	long: "ignore-file",
	defaultValue: () => ""
})

async function main(ignoreFilePath: string) {
	let ignoreFile = null;
	if (ignoreFilePath != "") {
    ignoreFile = new IgnoreFile(ignoreFilePath);
	}

	let data = "";
	for await (const chunk of process.stdin) data += chunk;

	let log = <Log | null>JSON.parse(data);
  let sr = new SummaryReporter(log, ignoreFile);

	process.exit(sr.execute());
}


const app = command({
	name: "sarif_reporter",
	args: {
		ignoreFileValue: ignoreFile
	},
	handler: ({ignoreFileValue}) => {
    main(ignoreFileValue);
	}
});

run(app, process.argv.slice(2));
