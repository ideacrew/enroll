# Dry Run Rake Tasks

## Overview

The 'dry_run' Rake tasks are designed to facilitate testing and verification of system behavior.
These tasks simulate various processes that occur during a specified year, such as open enrollment, application renewals, and notice generation with robust logging and reporting.
This README provides an overview of these tasks, their usages, steps, and expectations.

## High-Level Goals

- Simulate key processes for a given year.
- Test and verify system behavior.
- Ensure that the environment is valid for a dry run.
- Create necessary data for testing.
- Execute commands and processes.
- Generate reports to verify results.

## Task Usages

The tasks are meant to be modular such that you can run them individually or in groups. Many of the tasks have dependencies on other tasks, so it is recommended to run them in the order they are listed below, unless you are testing a specific process.

The rake tasks are divided into the following namespaces:

- `dry_run`: The top level namespace for dry run tasks.
- `dry_run:validations`: The namespace for tasks that validate the environment for a dry run.
- `dry_run:data`: The namespace for tasks that create and delete data for a dry run.
- `dry_run:commands`: The namespace for tasks that execute commands for a dry run.
- `dry_run:reports`: The namespace for tasks that generate reports for a dry run.

You can run `bundle exec rake -T dry_run` to see a list of all dry run tasks.

The following sections describe various top level tasks and their usages.

### Rake Task: `dry_run:all[year]`

- This is the main Rake task for initiating a complete dry run for a specific year.
- It provides options to customize the dry run process.

#### Usage:

```bash
- rake dry_run:all[year] -- [--force] [--refresh]
  - 'year' (optional): The year for which the dry run will be performed. Defaults to the next year if not provided.
  - '--force' (optional): Specify '--force' to skip the environment validation step.
  - '--refresh' (optional): Specify '--refresh' to perform a hard refresh, which deletes existing data.
```

#### Example:

```bash
rake dry_run:all[2024] -- --refresh
```

#### Steps and Expectations

The `dry_run:all` Rake task follows a series of steps to simulate various processes for the specified year. Here are the steps and what to expect:

1. **Environment Validation**: (skipped if '--force' flag is provided)
2. **Delete Existing Data (Optional):** (skipped if '--refresh' flag is not provided)
3. **Data Creation:** - Create necessary data for the dry run. This includes products, benefit packages, etc.
4. **Open Enrollment:**
5. **Renew financial assistance applications:**
6. **Determine financial assistance eligibility:**
7. **Renew HBX Enrollments:** - Execute commands to renew HBX enrollments for the specified year.
8. **Trigger Notices:** - Execute commands to trigger renewal notices for the specified year.
9. **Generate Reports:** - Generate reports based on the results of the dry run. See the 'Reports' section below for more information.

By following these steps, you can effectively conduct dry runs for testing and verifying the system's behavior for an upcoming year. Take a look at the following sections for more information about each step.

### Rake Task: `dry_run:validations[year]`

- This Rake task validates the environment to ensure that it is valid for a dry run.
- It checks for the existence of necessary data and resources, and it verifies that the environment is configured correctly. For any issues, it provides helpful error messages and suggestions for resolving them and exits.
- For pre-requisites that cannot be automatically verified (for example those outside of Enroll), it provides instructions for verifying them manually.

#### Usage:

```bash
rake dry_run:validations[2024]
```

#### Expectations

1. **Income thresholds are present for the given year**: (Automatic: Exits if not present)
2. **Affordability thresholds are present for the given year** (Manual: Requires manual verification)

### Rake Task: `dry_run:data:delete_all[year]`

- This Rake task deletes all data for the specified year.
- It is meant to be used in conjunction with the `dry_run:all` Rake task, which will create the necessary data for the dry run.
- It is also useful for deleting all data created by `dry_run:data:create_all` after a dry run is complete.

#### Usage:

```bash
rake dry_run:data:delete_all[2024]
```

#### Expectations

1. **The following data is deleted for the given year:**

- Service Areas
- Rating Areas
- Actuarial Factors
- Plans
- Products
- Benefit Coverage Periods
- Benefit Packages
- Benefit Market Catalogs
- Financial Assistance Applications (to rollback renewals)
- HBX Enrollments (to rollback renewals)

### Rake Task: `dry_run:data:create_all[year]`

- This Rake task creates all necessary data for the specified year.
- It is meant to be used in conjunction with the `dry_run:all` Rake task, which will simulate various processes for the specified year.
- It is also useful for creating all data necessary for `dry_run:commands:open_enrollment` without having to run the entire dry run process.

#### Usage:

```bash
rake dry_run:data:create_all[2024]
```

#### Expectations

The following data is created for the given year:

- Service Areas
- Rating Areas
- Actuarial Factors
- Plans
- Products
- Benefit Coverage Periods
- Benefit Packages
- Benefit Market Catalogs

### Rake Task: `dry_run:commands:open_enrollment[year]`

- This Rake task executes commands to simulate the open enrollment process for the specified year.
- It is recommended to run `dry_run:data:create_all` before running this task to ensure that all necessary data is present.
- The top level rake `dry_run:open_enrollment[year]` is a shortcut to run `dry_run:data:create_all` and `dry_run:commands:open_enrollment` in sequence.

#### Usage:

```bash
rake dry_run:commands:open_enrollment[2024]
```

#### Expectations

The current years open enrollment is closed and the next years open enrollment is open.

### Rake Task: `dry_run:commands:renew_applications[year]`

- This Rake task executes commands to simulate the financial assistance application renewal process for the specified year.

#### Usage:

```bash
rake dry_run:commands:renew_applications[2024]
```

#### Expectations

All eligible Financial assistance applications are renewed for the given year.

### Rake Task: `dry_run:commands:determine_applications[year]`

- This Rake task executes commands to trigger the financial assistance eligibility determination process for the specified year.
- It is recommended to wait a while after running `dry_run:commands:renew_applications` before running this task to ensure that all necessary applications are renewed.

#### Usage:

```bash
rake dry_run:commands:determine_applications[2024]
```

#### Expectations

All eligible Financial assistance application renewals are determined for the given year.

### Rake Task: `dry_run:commands:renew_enrollments[year]`

- This Rake task executes commands to trigger the HBX enrollment renewal process for the specified year.

#### Usage:

```bash
rake dry_run:commands:renew_enrollments[2024]
```

#### Expectations

All eligible HBX enrollments are renewed for the given year.

### Rake Task: `dry_run:commands:notify[year]`

- This Rake task executes commands to trigger the renewal notice generation process for the specified year.
- It is recommended to wait a while after running `dry_run:commands:renew_applications` and `dry_run:commands:renew_enrollments` before running this task to ensure that all necessary applications, and enrollments are renewed.

#### Usage:

```bash
rake dry_run:commands:notify[2024]
```

#### Expectations

All eligible renewal notices are generated for the given year.

### Rake Task: `dry_run:reports:all[year]`

- This Rake task generates all reports for the specified year.
- It is useful for generating all reports after a dry run is complete.
- Included in the report is a summary of the dry run process, which includes expectations, results, and any errors encountered.

#### Usage:

```bash
rake dry_run:reports:all[2024]
```

#### Expectations

The following reports are generated for the given year:

- Application Renewal Reports
  - Summary of all financial assistance applications that should be renewed. (`dry_run/renewal_eligible_families_[year].csv`)
  - Summary of all financial assistance applications that were renewed. (`dry_run/renewal_eligible_families_who_renewed_[year].csv`)
  - Summary of all financial assistance applications that were not renewed with possible causes. (`dry_run/renewal_eligible_families_who_did_not_renew_[year].csv`)

## Logging

The dry run process logs all steps and results to the file `dry_run/dry_run.log`. This log file is useful for debugging issues and verifying results.

## Development

It is encouraged to add new tasks to simulate new processes. Here are some guidelines to follow:

- **Modular and flexible**: Tasks should be modular and flexible such that you can run individual tasks or groups of tasks to test specific processes.
- **Repeatable**: Tasks should be repeatable such that you can run the same tasks multiple times to test and verify the system's behavior.
- **Reversible**: Tasks should be reversible such that you can undo the effects of the dry run process.
- **Customizable**: Tasks should be customizable such that you can specify options to customize the dry run process.
- **Extensible**: Tasks should be extensible such that you can add new tasks to simulate new processes.
- **Robust**: Tasks should be robust such that they provide helpful error messages and suggestions for resolving issues. Use the `log` method found in `lib/dry_run/helpers.rb` to log messages.
- **Informative**: Tasks should be informative such that they generate reports to summarize the results of the dry run process.
- **Easy to use**: Tasks should be easy to use such that they provide a top level task to run the entire dry run process.
- **Well documented**: Top level tasks should be well documented such that they provide helpful information about their usages, steps, and expectations.
  This documentation serves as a source of truth for the dry run process.
- **Well maintained**: Tasks should be well maintained such that they are kept up to date with the latest changes to the system.
- **Well organized**: Tasks should be well organized and named such that they are easy to find and understand.

## Notes

- Many of the tasks are useful outside of the dry run process. For example, `dry_run:data:create_all` is useful for creating all necessary data for `dry_run:commands:open_enrollment` when testing features depended on open enrollment.
  We should consider moving these tasks to a more appropriate namespace.
