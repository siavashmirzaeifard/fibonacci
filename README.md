# fibonacci

Sample Fibonacci Flutter project with SQFLite.

## Getting Started

This project is based on SQFLite database, because we wanna see what numbers were previously requested and what is the result. So we need a storage to hold these values. For this project I prefer to use a SQLite technology in flutter instead of the NoSQL databases.
When you open the app for first time, there is no result in history and as soon as you add a new value and calculate, then your history will create and it's reachable since you dont uninstall the app or clear the application storage.

Addition: When we're using SQFLite we need to add Path and Path_Provider and SQFLite dependency in our pubspec.yaml.
