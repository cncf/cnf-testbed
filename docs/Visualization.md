## How to use the packet generator visualization

When deploying the [packet generator](comparison/ansible/packet_generator.yml), visualization features will be deployed by default. This can be changed my modifying the following line:
```
    visualization: true
```

The steps to deploy the packet generator can be found [here](docs/Deploy_K8s_CNF_Testbed.md#deploy-packet-generator), and will not be covered further in this document.

Once deployed, Kibana (visualization dashboard) can be reached at `https://<public server IP>:5601`

When initially trying to access the page, you will receive a warning about the certificate. The reason behind this is the use of a self-signed certificate, which can not be validated by browsers (Chrome, Firefox, IE etc.). All of the browsers should provide an option to ignore the warning or accept the risk and continue.

After a few seconds you should see a login screen. Kibana has been pre-configured with two users, one for read-only purposes and one for administration and adding addiional visualizations and dashboards:

* User: elastic
  - Password can be found by logging on to the server through SSH and checking the file `/root/elastic_pass`
  - This account has administrator privileges, and can be used to create/modify/delete both users and additional visualizations and dashboards.
* User: cnftestbed
  - Password: cnftestbed
  - This is the read-only user that can view existing visualizations and dashboards. The user also has access to the "raw" data coming from NFVbench throug the discover tab. This is useful to view metrics that are not displayed in any of the existing dashboards. All of the filtering options for Kibana can also be used with this user

### Limitations
Due to way the cnftestbed user is created, once logged in the password to the user can be modified. This can potentially lock out anyone else from accessing this user. In case this happens, the password can be modified from the elastic user.
