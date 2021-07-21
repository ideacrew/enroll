---
title: 'Running Golden Seed Locally'
date: 2021-07-21T12:12:25-05:00
draft: true
---

# Golden Seed Implementation Steps

1.  Start server: `rails s`

2.  Start redis-server in another terminal. To do this run: `redis-server`

        If redis is not found, run: ```brew install redis```

3.  In a third terminal window, start sidekiq: `bundle exec sidekiq start`

4.  \*Make sure there is enough memory on the server to run both of those commands

5.  Open Enroll in your browser by going to: **http://localhost:3000/** if running locally

6.  Log in as hbx admin

7.  Go to admin dropdown menu and click **Data Seeds**

8.  Click **New Seed** at the top of the page

9.  Click **individual market seed**

10. Choose file: **individual market seed**

    You will see the text: **seed pending**

You can check the seeding progress by looking at your terminal window

10. The seeding will be complete when you see **seed complete**

Other Notes:

If you want to add more users copy and paste the values to the spreadsheet

The individual market seed csv file uses the faker gem to make unique user entries
