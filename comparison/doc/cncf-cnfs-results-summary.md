cncf-cnfs-results-summary.md

[Text not rendered in markdown format, will be soon.]

Overview
  xNF service topology (aka chain) matrix:
    vsc: vnf_service_chain aka vnf_snake_test
    csc: cnf_service_chain aka cnf_snake_test
    csp: cnf_service_pipeline aka cnf_pipeline_test

  compared configurations
    row: number_of_service_chains or _service_pipelines
    col: #nfs
    metric: performance
    * code in https://github.com/cncf/cnfs
    ** code requires development

Summary of Throughput Results

  All results in [Mpps] at 64B L2 frame size untagged Ethernet MRR

    FD.io CSIT 2n-skx testbed t22:

      vsc   001   002   004   008
      001   4.1   2.6   1.7   0.5
      002   3.0   1.3   0.2   0.005
      004   ---   ---   ---   ---
      008   ---   ---   ---   ---

      csc   001   002   004   008
      001   5.1   3.5   2.1   1.1
      002   3.2   1.7   0.4   0.2
      004   ---   ---   ---   ---
      008   ---   ---   ---   ---

      csp   001   002   004   008
      001   5.3   5.2   5.4   5.4
      002   3.2   1.7   0.6   0.2
      004   ---   ---   ---   ---
      008   ---   ---   ---   ---

    packet.net 2n-skx testbed:

      vsc   001   002   004   008
      001   ---   ---   ---   ---
      002   ---   ---   ---   ---
      004   ---   ---   ---   ---
      008   ---   ---   ---   ---

      csc   001   002   004   008
      001   ---   ---   ---   ---
      002   ---   ---   ---   ---
      004   ---   ---   ---   ---
      008   ---   ---   ---   ---

      csp   001   002   004   008
      001   ---   ---   ---   ---
      002   ---   ---   ---   ---
      004   ---   ---   ---   ---
      008   ---   ---   ---   ---

---
end
