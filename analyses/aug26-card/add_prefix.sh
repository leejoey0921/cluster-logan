for f in $(ls *.id90.f?a) ; do b=${f%%.*};  sed "s/>/>$b./g" -i $f; done

