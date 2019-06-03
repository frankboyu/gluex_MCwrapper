#!/bin/bash -f                                                                                                                                                                                                      

source /osgpool/halld/tbritton/local_setup.sh

if [[ -f /osgpool/halld/tbritton/.ALLSTOP ]]; then
    echo "ALL STOP DETECTED"
fi

if [[ `ps all -u tbritton | grep MCMover.csh | grep -v grep | wc -l` == 2 ]]; then
    echo "moving"
    input_dir=/osgpool/halld/tbritton/REQUESTEDMC_OUTPUT/
    output_dir=/cache/halld/halld-scratch/REQUESTED_MC/
    # move slag-like files in the input directory out of the way
    mkdir -pv $input_dir/slag
    find $input_dir -maxdepth 2 -mindepth 2 -type f -exec mv -v {} $input_dir/slag/ \;

    #find me the dirs
    transArray=()
    while IFS=  read -r -d $'\0'; do
        transArray+=("$REPLY")
    done < <(find $input_dir/ -mindepth 2 -maxdepth 2 -type d -not -name ".*" -print0)
    
    #echo ${transArray[*]}
    for dir in ${transArray[@]}
    do
        #echo $dir
        projpath=`echo $dir | awk '{split($0,arr,"REQUESTEDMC_OUTPUT"); print arr[2]}'`
        echo $projpath
        mkdir -p $output_dir/$projpath/
        
        rsync_command="rsync -pruvt $dir/ $output_dir/$projpath/" #--exclude $input_dir/slag"
        echo $rsync_command
        status="255"
        while [ "$status" -eq "255" ]
        do
            $rsync_command
            status="$?"
            echo status = $status
            sleep 1
        done
    done

    cd $output_dir
    # make list of files in the output directory
    find . -type f | sort > /tmp/output_files_list.txt
    cd $input_dir
    # make list of files in the input directory
    find . -type f -mmin +120 | sort > /tmp/input_files_list.txt
    echo `comm -12 /tmp/input_files_list.txt /tmp/output_files_list.txt`
    if [[ `comm -12 /tmp/input_files_list.txt /tmp/output_files_list.txt | wc -l` != 0 ]]; then
        comm -12 /tmp/input_files_list.txt /tmp/output_files_list.txt | xargs rm -v
    fi

    #clean empty directories
    #find $input_dir -depth -empty -type d mmin -2880 -exec rmdir {} \;
    
else
    echo "too many running"
fi