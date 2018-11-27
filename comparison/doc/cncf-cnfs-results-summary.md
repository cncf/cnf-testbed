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

      vsc   001   002   004   006   008   010
      001   6.1   3.5   2.3   1.5   1.1   ---
      002   3.9   1.5   0.3   0.1   0.1   ---
      004   ---   ---   ---   ---   ---   ---
      008   ---   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

      csc   001   002   004   006   008   010
      001   6.4   3.8   2.2   1.6   1.2   ---
      002   5.8   3.4   1.8   1.2   0.9   ---
      004   ---   ---   ---   ---   ---   ---
      008   ---   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

      csp   001   002   004   006   008   010
      001   6.3   6.3   6.3   6.4   6.5   ---
      002   5.8   5.6   5.6   5.6   5.5   ---
      004   ---   ---   ---   ---   ---   ---
      008   ---   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

    packet.net 2n-skx testbed:

      vsc   001   002   004   006   008   010
      001   5.4   3.1   1.5   1.2   0.9   ---
      002   2.9   0.9   0.2   ---   ---   ---
      004   ---   ---   ---   ---   ---   ---
      008   ---   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

      csc   001   002   004   006   008   010
      001   5.6   3.3   1.9   1.3   1.0   ---
      002   5.8   3.4   1.9   ---   ---   ---
      004   ---   ---   ---   ---   ---   ---
      008   ---   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

      csp   001   002   004   006   008   010
      001   5.6   5.7   5.6   5.7   5.7   ---
      002   5.6   5.6   5.6   ---   ---   ---
      004   ---   ---   ---   ---   ---   ---
      008   ---   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

---
end
