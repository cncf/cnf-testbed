#! /bin/bash

search_string="Intel Corporation Ethernet Controller"

output=($(sudo lspci | grep "$search_string" | awk '{print $1}'))


cat > tmp_out <<EOF
hello ${search_string} end
EOF

