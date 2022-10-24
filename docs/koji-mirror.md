# Koji Mirror

| | mirror01.koji.aws.theforeman.org |
|-|-|
| type | AWS EC2 us-east-1 |
| flavor | t2.medium |
| OS | RHEL 8 |
| CPUs | 2 |
| RAM | 4GB |
| Storage | xvda - 10G root, xvdf - 1TB data |

## Subscriptions

* To obtain RHEL bits, the machine needs to be subscribed to the Red Hat Portal
* The subscription is done using the `theforeman` account, that has "Red Hat Enterprise Linux for Open Source Infrastructure" subscriptions

```console
# subscription-manager register
Registering to: subscription.rhsm.redhat.com:443/subscription
Username: theforeman
Password:
The system has been registered with ID: ada1f23a-52fd-4743-87b9-162ac5c285eb
The registered system name is: mirror01.koji.aws.theforeman.org

# subscription-manager list --available
+-------------------------------------------+
    Available Subscriptions
+-------------------------------------------+
Subscription Name:   Red Hat Enterprise Linux for Open Source Infrastructure
Provides:            Red Hat Beta
                     Red Hat Enterprise Linux EUS Compute Node
                     Red Hat Enterprise Linux for x86_64
                     …
SKU:                 RH02517F3
Pool ID:             2c94327f82fed3340183459b74220afa

# subscription-manager attach --pool 2c94327f82fed3340183459b74220afa
Successfully attached a subscription for: Red Hat Enterprise Linux for Open Source Infrastructure
```

## Mirroring

TBD, describe reposync

## Serving

TBD, describe apache-to-koji-only setup
