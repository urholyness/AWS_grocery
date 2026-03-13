# AWS Grocery Store Project

Hi there! This is my project for the Masterschools program. It's an e-commerce website for a grocery store that I built and deployed on AWS.

This README is a bit of a journal of my learning process through the cloud computing part of the course.

## The Journey (The Fun Part!)

Here's a week-by-week breakdown of how I built and deployed this thing.

### Week 2 & 3: Getting Started with EC2

- **What I did:** I started with the basics of AWS. I learned how to create an EC2 instance, which is basically a virtual server in the cloud.
- **The Goal:** The main goal was to get the application running on this server so anyone could access it from the internet.
- **In the code:** You can see the `aws_instance` resource in `infrastructure/main.tf`. This is the Terraform code that creates the EC2 server.

### Week 4: Docker Time!

- **What I did:** I learned about Docker and how to put my application into a container. This makes it easier to run the app anywhere.
- **The Goal:** Get the backend (the Python part) running inside a Docker container on the EC2 instance.
- **In the code:** Check out the `Dockerfile` in the `backend` folder. It's a simple recipe for building the container image for my app.

### Week 5: Adding a Real Database with RDS

- **What I did:** My app needed a database, so I learned how to use Amazon RDS (Relational Database Service). I set up a PostgreSQL database.
- **The Goal:** To have a proper, managed database that my application could connect to, instead of just a file on the server.
- **In the code:** In `infrastructure/main.tf`, you'll find the `aws_db_instance` resource. This is the Terraform code for the RDS database.

### Week 6: Infrastructure as Code (IaC) with Terraform

- **What I did:** This was a cool week. I learned how to write code to create my cloud stuff instead of clicking around in the AWS console. I used Terraform for this.
- **The Goal:** To automate the whole setup process. Now I can destroy and recreate my entire application infrastructure with a few commands.
- **In the code:** The whole `infrastructure` folder is dedicated to this! `main.tf` is the main file that defines almost everything: the server, the database, the networking, etc.

### Week 7: Storing Files in S3

- **What I did:** I needed a place to store user profile pictures. I learned about Amazon S3 (Simple Storage Service) for this.
- **The Goal:** Modify the application so that when a user uploads an avatar, it gets saved in an S3 bucket.
- **In the code:** `infrastructure/s3.tf` has the code that creates the S3 bucket. I also had to create an IAM role (also in the `.tf` files) to give my EC2 instance permission to talk to the S3 bucket.

### Week 8: Tying it all together

- **What I did:** This week was all about finishing up the project, making sure everything works, and writing this README!
- **The Goal:** Have a complete, working project that shows everything I learned.

## About the Project

This is a full-stack e-commerce application with:
- A **React frontend** (in the `frontend` folder).
- A **Python (Flask) backend** (in the `backend` folder).
- All the AWS infrastructure defined in **Terraform** (in the `infrastructure` folder).

Thanks for checking out my project!

/assets/infra.png

