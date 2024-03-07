history clear
project -load fm_radio_test.prj
project -run  
timing_corr::q_opt_corr_qii  -impl_name {/home/mwp8699/CE387-Assignments/final_project/syn/fm_radio_test.prj|rev_1}  -impl_result {/home/mwp8699/CE387-Assignments/final_project/syn/rev_1/proj_1.vqm}  -sdc_verif 
timing_corr::q_correlate_db_qii  -paths_per 1  -qor 1  -sdc_verif  -impl_name {/home/mwp8699/CE387-Assignments/final_project/syn/fm_radio_test.prj|rev_1}  -impl_result {/home/mwp8699/CE387-Assignments/final_project/syn/rev_1/proj_1.vqm}  -load_sta 
timing_corr::pro_qii_corr  -paths_per 1  -qor 1  -sdc_verif  -impl_name {/home/mwp8699/CE387-Assignments/final_project/syn/fm_radio_test.prj|rev_1}  -impl_result {/home/mwp8699/CE387-Assignments/final_project/syn/rev_1/proj_1.vqm}  -load_sta 
timing_corr::q_correlate_db_qii  -paths_per 1  -qor 1  -sdc_verif  -impl_name {/home/mwp8699/CE387-Assignments/final_project/syn/fm_radio_test.prj|rev_1}  -impl_result {/home/mwp8699/CE387-Assignments/final_project/syn/rev_1/proj_1.vqm}  -load_sta 
project -save /home/mwp8699/CE387-Assignments/final_project/syn/fm_radio_test.prj 
project -close /home/mwp8699/CE387-Assignments/final_project/syn/fm_radio_test.prj
