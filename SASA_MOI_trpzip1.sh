#!/bin/bash

echo "AP" > sasa_trip.txt
echo "Time     nr_at Time   Itot    Ix    Iy    Iz" > inertia_trip.txt

#cluster peptides across periodic boundaries
         echo 1 1 1 | gmx trjconv -f "trpzip1_md.gro" -s "trpzip1_md.tpr" -pbc cluster -center -o "trpzip1_clustered.gro"
         
#calculate change in solvent-accessible surface area
         echo 1 1 | gmx sasa -f "trpzip1_em.gro" -s "trpzip1_em.tpr" -o "trpzip1_sasa_in.xvg" -surface 'group "Protein"' -probe 0.4
         echo 1 1 | gmx sasa -f "trpzip1_clustered.gro" -s "trpzip1_md.tpr" -o "trpzip1_sasa_fin.xvg" -surface 'group "Protein"' -probe 0.4
         sasa_in=`tail -n 1 "trpzip1_sasa_in.xvg" | awk '{print $2}'`
         sasa_fin=`tail -n 1 "trpzip1_sasa_fin.xvg" | awk '{print $2}'`
         echo $sasa_in
         AP=`bc <<< "scale=3 ; $sasa_in/$sasa_fin"`
         echo $AP >> sasa_trip.txt
         
#calculate moments of inertia along principal axes of largest cluster
         gmx make_ndx -f "trpzip1_md.gro" -o "trpzip1_noW.ndx" < options.txt
         echo 1 | gmx convert-tpr -s "trpzip1_md.tpr" -n "trpzip1_noW.ndx" -o "trpzip1_noW_0.tpr"
         gmx convert-tpr -s "trpzip1_noW_0.tpr" -nsteps -1 -o "trpzip1_noW.tpr"
         echo 1 | gmx clustsize -f "trpzip1_md.xtc" -s "trpzip1_md.tpr" -mcn "trpzip1_maxclust.ndx" -n "trpzip1_noW.ndx" -cut 0.5
         gmx trjconv -f "trpzip1_clustered.gro" -s "trpzip1_noW.tpr" -n "trpzip1_maxclust.ndx" -o "trpzip1_maxclust.gro"
         gmx convert-tpr -s "trpzip1_noW.tpr" -n "trpzip1_maxclust.ndx" -o "trpzip1_maxclust_0.tpr"
         gmx convert-tpr -s "trpzip1_maxclust_0.tpr" -nsteps -1 -o "trpzip1_maxclust.tpr"
         echo 1 1 | gmx editconf -f "trpzip1_maxclust.gro" -princ -c -o "trpzip1_princ.gro"
         echo 1 | gmx gyrate -f "trpzip1_princ.gro" -s "trpzip1_maxclust.tpr" -moi -o "trpzip1_gyrate.xvg"
         mois=`tail -n 1 "trpzip1_gyrate.xvg"`
         nratominclust=`tail -n 1 "maxclust.xvg"`
         echo $nratominclust $mois >> inertia_trip.txt
       done
   done
done

# cleanup

rm -f \#*

exit
