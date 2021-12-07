// import { FilesWithRunTime, GroupOverview } from '../models';
// import { getGroupRunTime, inMinutesNum } from './splitFilesIntoGroups';

// export const createGroupOverview = (
//   groupRunTimes: FilesWithRunTime[]
// ): GroupOverview[] => {
//   return groupRunTimes.map((group, index) => {
//     const totalRunTime = inMinutesNum(Math.floor(getGroupRunTime(group)));

//     return {
//       groupNumber: index + 1,
//       numberOfFiles: group.files.length,
//       totalRunTime,
//     };
//   });
// };
