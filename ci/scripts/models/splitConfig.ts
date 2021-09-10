import { FileWithRuntime } from './fileWithRuntime';

export interface FilesWithRunTime {
  files: (FileWithRuntime | undefined)[];
}

export interface GroupOverview {
  groupNumber: number;
  numberOfFiles: number;
  totalRunTime: number;
}

export interface FileGroup {
  files: string[];
}

export type SplitConfig = FileGroup[];
