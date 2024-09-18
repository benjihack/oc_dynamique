#!/bin/bash

# Définir les seuils pour détecter si le GPU est sollicité ou non
UTILISATION_MAX=50  # Seuil d'utilisation GPU en pourcentage pour basculer vers le profil "high-oc"
UTILISATION_MIN=10  # Seuil pour basculer vers le profil "low_oc"

# Variables pour suivre l'état des GPU (si high-oc ou low_oc est déjà appliqué)
declare -A GPU_STATE

# Obtenir le nombre total de GPU via nvidia-smi
TOTAL_GPU=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits | head -n 1)

# Fonction pour vérifier les overclocks actuels d'un GPU
check_current_oc() {
  local gpu_index=$1
  local current_clock=$(nvtool -i $gpu_index --getclocks | grep "GPU clocks locked" | awk '{print $5}')
  local current_mem=$(nvtool -i $gpu_index --getclocks | grep "MEM clocks locked" | awk '{print $5}')

  echo "$current_clock $current_mem"
}

# Boucle infinie pour vérifier l'utilisation des GPU
while true; do
  for (( i=0; i<$TOTAL_GPU; i++ )); do
    # Récupérer l'utilisation du GPU via nvidia-smi pour le GPU indexé par $i
    GPU_UTILISATION=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits -i $i | tr -d ' %')

    # Vérifier que la valeur est un entier valide
    if [[ "$GPU_UTILISATION" =~ ^[0-9]+$ ]]; then
      # Récupérer les overclocks actuels
      read -r current_clock current_mem <<< $(check_current_oc $i)

      # Si l'utilisation du GPU dépasse le seuil maximum et que le profil high-oc n'a pas encore été appliqué
      if [ "$GPU_UTILISATION" -gt "$UTILISATION_MAX" ] && [ "${GPU_STATE[$i]}" != "high-oc" ]; then
        # Vérifier si les overclocks actuels sont déjà les bons pour high-oc
        if [ "$current_clock" != "1400" ] || [ "$current_mem" != "5001" ]; then
          echo "Passer au profil high-oc pour GPU #$i"
          nvtool -i $i --setclocks 1400 --setcoreoffset 250 --setmem 5001  # Appliquer les paramètres pour high-oc
          GPU_STATE[$i]="high-oc"  # Enregistrer l'état
        else
          echo "Les overclocks high-oc sont déjà appliqués pour GPU #$i"
        fi

      # Si l'utilisation du GPU est inférieure au seuil minimum et que le profil low_oc n'a pas encore été appliqué
      elif [ "$GPU_UTILISATION" -lt "$UTILISATION_MIN" ] && [ "${GPU_STATE[$i]}" != "low_oc" ]; then
        # Vérifier si les overclocks actuels sont déjà les bons pour low_oc
        if [ "$current_clock" != "210" ] || [ "$current_mem" != "405" ]; then
          echo "Passer au profil low_oc pour GPU #$i"
          nvtool -i $i --setclocks 210 --setcoreoffset 0 --setmem 405  # Appliquer les paramètres pour low_oc
          GPU_STATE[$i]="low_oc"  # Enregistrer l'état
        else
          echo "Les overclocks low_oc sont déjà appliqués pour GPU #$i"
        fi
      fi
    else
      echo "Erreur : utilisation GPU invalide pour GPU #$i - $GPU_UTILISATION"
    fi
  done

  # Attendre 60 secondes avant la prochaine vérification
  sleep 60
done
