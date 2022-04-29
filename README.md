# Kubecon EU 2022 Demo

Prerequisite

1. RDS running.
2. Vitess running in unmanaged and managed mode.
3. Rails app running.


Flow of Demo
1. configured RDS to startup.
2. run rails app against it.
3. start vitess cluster in unmanaged mode.
4. migrate running rails app against vitess unmanaged.
5. start vitess cluster in managed mode.
6. migrate data.
7. show data sync happening.
8. cutover to managed.
9. show data sync happening to rds.

 
