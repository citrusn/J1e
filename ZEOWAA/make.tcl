exec quartus_cdb j1_cpu -c top --update_mif
# project_open j1_cpu
load_package flow
execute_flow -compile
exec quartus_pgm  ./output_files/chain1.cdf

exec quartus_cdb j1_cpu -c top --update_mif ; execute_flow -compile ; exec quartus_pgm  ./output_files/chain1.cdf
