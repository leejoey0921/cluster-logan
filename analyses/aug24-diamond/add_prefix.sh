# for the P4's
for f in $(ls *.fa) ; do b=${f%.*};  sed "s/>/>$b./g" -i $b.fa; done

