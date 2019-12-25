# Prometheus Blackbox Experiement

I need to monitor some existing sites and I don't want to modify them to add `/metrics` endpoints. Prometheus' Blackbox Exporter seems to fit the bill. I will purposefully not use Docker Compose for this experiment because the server that will be used to host this system does not have it installed. This is meant to be an experiment to learn the system.

## Usage

```bash
PBE_EMAIL_TO=myemail@test.test PBE_EMAIL_FROM=alerter@test.test PBE_EMAIL_PASSWORD=superS3cretPa55word ./setup.sh https://example.com https://subdomain.example.com
```

The following environment variables must be specified

| Name               | Value                                             |
| ------------------ | ------------------------------------------------- |
| PBE_EMAIL_FROM     | The email account to use to send the alert emails |
| PBE_EMAIL_PASSWORD | The password for the PBE_EMAIL_FROM account       |
| PBE_EMAIL_TO       | Where to send alert emails                        |

Pass all domains to monitor as parameters to the function.

The setup script will create `prometheus.yml` and `alertmanager.yml` files, create a docker network for the running containers, and spin up the containers within the newly created network.

## Why use a user-defined network?

A user-defined network provides automatic DNS resolution using the container names.

## What is "PBE"

`PBE` is the prefix used for this project. It stands for Prometheus Blackbox Experiment.
