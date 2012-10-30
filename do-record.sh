#!/bin/sh
echo "CHANNEL : $CHANNEL"
echo "DURATION: $DURATION"
echo "OUTPUT  : $OUTPUT"
echo "TUNER : $TUNER"
echo "TYPE : $TYPE"
echo "MODE : $MODE"
echo "SID  : $SID"

# fail safe
  case $CHANNEL in
   101|102|191|192|193)
     if [ $SID = 'hd' ]; then
        SID=$CHANNEL
     fi ;;
  esac
  if [ -z $SID ]; then
     SID='hd'
  fi

 ############################################
 ## FILE_NAME=`echo ${OUTPUT}|cut -d "/" -f6-`
 FILE_NAME=`echo ${OUTPUT}|sed -e 's/\/var\/www\/epgrec\/video\///g'`
##  RECORDER=recpt1
 RECORDER=/usr/local/bin/recpt1
 ENCODER=ffmpeg

 EPGLIB_DIR=/usr/local/share/ffmpeg/ 
 ## PRESET=libx264-hq-ts.ffpreset
 PRESET=libx264-ipod640.ffpreset
 HQ_PRESET=libx264-hq-ts-ctm1.ffpreset

 TMP_OUTPUT=${OUTPUT}_tmp.ts
 TMP2_OUTPUT=`date '+%Y%m%d%H%M%S'`.mp4
 VLIB_DIR=/var/www/epgrec/video/Video-Library
 BASELIB_DIR=/var/www/epgrec/video

 ENC_SRV_NAME=192.168.11.12
 ENC_SRV_USER=tobe
 ENC_TMP_DIR=/home/tobe/Videos/TV-RECS
 ENC_SRV_SECRET_KEY=/var/www/.ssh/id_rsa_encoder
 LOG_FILE=/var/www/epgrec/logs/rec_log_`date +%Y%m%d`.log
 ## `date +%Y%m%d%H%M%S`\t:\t

### ssh -i /var/www/epgrec/video/id_rsa_encoder tobe@192.168.11.12

 #CMD
  ## FULL_TS="$RECORDER --b25 --strip epg $CHANNEL $DURATION ${OUTPUT} >/dev/null"
  FULL_TS="$RECORDER --b25 --strip --sid epg $CHANNEL $DURATION ${OUTPUT} >/dev/null"
  MIN_TS="$RECORDER --b25 --strip --sid $SID $CHANNEL $DURATION ${OUTPUT} >/dev/null"
##  ENCODE="${ENCODER} -y -i ${TMP_OUTPUT} -f mp4 -vcodec libx264 -fpre ${EPGLIB_DIR}${PRESET} -threads 0 -r 30000/1001 -deinterlace -b 2M -bt 2M -aspect 16:9 -vsync 1 -acodec libfaac -ac 2 -ar 48000 -ab 128k -map 0:0 -map 0:1 ${OUTPUT}"
  ENCODE01="${ENCODER} -y -i pipe:0 -f mp4 -vcodec libx264 -fpre ${EPGLIB_DIR}${PRESET} -threads 0 -r 30000/1001 -deinterlace -b 2M -bt 2M -aspect 16:9 -vsync 1 -acodec libfaac -ac 2 -ar 48000 -ab 192k -map 0:0 -map 0:1 ${ENC_TMP_DIR}/${FILE_NAME}"
  ENCODE02="${ENCODER} -y -i pipe:0 -f mp4 -vcodec libx264 -fpre ${EPGLIB_DIR}${HQ_PRESET} -threads 0 -r 30000/1001 -deinterlace -b 2M -bt 2M -aspect 16:9 -vsync 1 -acodec libfaac -ac 2 -ar 48000 -ab 192k -map 0:0 -map 0:1 ${ENC_TMP_DIR}/${FILE_NAME}"
  ENCODE04="${ENCODER} -y -i pipe:0 -f mp4 -vcodec libx264 -fpre ${EPGLIB_DIR}${HQ_PRESET} -threads 0 -r 30000/1001 -deinterlace -b 2M -bt 2M -aspect 16:9 -s hd480 -vsync 1 -acodec libfaac -ac 2 -ar 48000 -ab 192k -map 0:0 -map 0:1 ${ENC_TMP_DIR}/${FILE_NAME}"
  ENCODE05="${ENCODER} -y -i pipe:0 -f mp4 -vcodec libx264 -fpre ${EPGLIB_DIR}${HQ_PRESET} -threads 0 -r 30000/1001 -deinterlace -b 2M -bt 2M -aspect 16:9 -s hd720 -vsync 1 -acodec libfaac -ac 2 -ar 48000 -ab 192k -map 0:0 -map 0:1 ${ENC_TMP_DIR}/${FILE_NAME}"
  RM_TMPFILE="rm -f ${ENC_TMP_DIR}/${TMP2_OUTPUT}"

###   "$ENCODER -y -i ${TMP_OUTPUT} -f mp4 -vcodec libx264 -fpre ${EPGREC_DIR}${PRESET} -threads 0 -r 30000/1001 -deinterlace -b 1M -bt 1M -aspect 16:9 -vsync 1 -acodec libfaac -ac 2 -ar 48000 -ab 128k -map 0:0 -map 0:1 ${OUTPUT}"
 ############################################



if [ ${MODE} = 0 ]; then
   # MODE=0では必ず無加工のTSを吐き出すこと
 ##    $RECORDER --b25 --strip --sid epg $CHANNEL $DURATION ${OUTPUT} >/dev/null
   $FULL_TS
elif [ ${MODE} = 1 ]; then
   # 目的のSIDのみ残す
###    $RECORDER --b25 --strip --sid $SID $CHANNEL $DURATION ${OUTPUT} >/dev/null
   echo "Start $OUTPUT by Minimum" >>$LOG_FILE
   $MIN_TS
   echo "Finish $OUTPUT by Minimum" >>$LOG_FILE

# mode 2 example is as follows
elif [ ${MODE} = 2 ]; then
   echo "Start $OUTPUT by ipad" >>$LOG_FILE
   $MIN_TS
   echo "Finish $OUTPUT by ipad" >>$LOG_FILE
   echo "Move $OUTPUT to $TMP_OUTPUT" >>$LOG_FILE
   mv $OUTPUT $TMP_OUTPUT
   echo "Start Encode $OUTPUT" >>$LOG_FILE
   cat ${TMP_OUTPUT} | ssh -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME} "${ENCODE01}"
   ## scp -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME}:${ENC_TMP_DIR}/${TMP2_OUTPUT} ${OUTPUT}
   echo "rm ${TMP_OUTPUT}" >>$LOG_FILE
   ## rm -f ${TMP_OUTPUT}
   ## ssh -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME} "${RM_TMPFILE}"

# mode 3 example is as follows
elif [ ${MODE} = 3 ]; then
   echo "`date +%Y%m%d%H%M%S`\t:\t Start $OUTPUT by no change size" >>$LOG_FILE
   $MIN_TS
   echo "`date +%Y%m%d%H%M%S`\t:\t Finish $OUTPUT by no change size" >>$LOG_FILE
   echo "`date +%Y%m%d%H%M%S`\t:\t Move $OUTPUT to $TMP_OUTPUT" >>$LOG_FILE
   mv $OUTPUT $TMP_OUTPUT
   echo "`date +%Y%m%d%H%M%S`\t:\t Start Encode $OUTPUT" >>$LOG_FILE
   echo "`date +%Y%m%d%H%M%S`\t:\t DO : ${ENCODE02}" >>$LOG_FILE
   cat ${TMP_OUTPUT} | ssh -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME} "${ENCODE02}"  >>${LOG_FILE} 2>&1
##   echo "`date +%Y%m%d%H%M%S`\t:\t scp $OUTPUT" >>$LOG_FILE
   ## scp -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME}:${ENC_TMP_DIR}/${TMP2_OUTPUT} ${OUTPUT}
   ln -s ${VLIB_DIR}/${FILE_NAME} ${BASELIB_DIR}/${FILE_NAME}
   echo "`date +%Y%m%d%H%M%S`\t:\t    ln -s ${VLIB_DIR}/${FILE_NAME} ${BASELIB_DIR}/${FILE_NAME}" >>$LOG_FILE
   rm -f ${TMP_OUTPUT}
   ## ssh -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME} "${RM_TMPFILE}"

# mode 4 hq480 ENCODE
elif [ ${MODE} = 4 ]; then
   echo "`date +%Y%m%d%H%M%S`\t:\t Start $OUTPUT by hd480" >>$LOG_FILE
   $MIN_TS
   echo "`date +%Y%m%d%H%M%S`\t:\t Finish $OUTPUT by hd480" >>$LOG_FILE
   echo "`date +%Y%m%d%H%M%S`\t:\t Move $OUTPUT to $TMP_OUTPUT" >>$LOG_FILE
   mv $OUTPUT $TMP_OUTPUT
   echo "$OUTPUT $TMP_OUTPUT" >>${LOG_FILE}
   echo "`date +%Y%m%d%H%M%S`\t:\t Start Encode $OUTPUT" >>$LOG_FILE
   cat ${TMP_OUTPUT} | ssh -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME} "${ENCODE04}" >>${LOG_FILE} 2>&1
   ##scp -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME}:${ENC_TMP_DIR}/${TMP2_OUTPUT} ${OUTPUT}
   ln -s ${VLIB_DIR}/${FILE_NAME} ${BASELIB_DIR}/${FILE_NAME}
   echo "`date +%Y%m%d%H%M%S`\t:\t    ln -s ${VLIB_DIR}/${FILE_NAME} ${BASELIB_DIR}/${FILE_NAME}" >>$LOG_FILE
   rm -f ${TMP_OUTPUT}
   ## ssh -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME} "${RM_TMPFILE}"

# mode 5 hq720 ENCODE
elif [ ${MODE} = 5 ]; then
   echo "`date +%Y%m%d%H%M%S`\t:\t Start $OUTPUT by hd720" >>$LOG_FILE
   $MIN_TS
   echo "`date +%Y%m%d%H%M%S`\t:\t Finish $OUTPUT by hd720" >>$LOG_FILE
   echo "`date +%Y%m%d%H%M%S`\t:\t Move $OUTPUT to $TMP_OUTPUT" >>$LOG_FILE
   mv $OUTPUT $TMP_OUTPUT
   echo "`date +%Y%m%d%H%M%S`\t:\t Start Encode $OUTPUT" >>$LOG_FILE
   cat ${TMP_OUTPUT} | ssh -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME} "${ENCODE05}"  >>${LOG_FILE} 2>&1
   echo "`date +%Y%m%d%H%M%S`\t:\t scp $OUTPUT" >>$LOG_FILE
   ## scp -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME}:${ENC_TMP_DIR}/${TMP2_OUTPUT} ${OUTPUT}
   ln -s ${VLIB_DIR}/${FILE_NAME} ${BASELIB_DIR}/${FILE_NAME}
   echo "`date +%Y%m%d%H%M%S`\t:\t    ln -s ${VLIB_DIR}/${FILE_NAME} ${BASELIB_DIR}/${FILE_NAME}" >>$LOG_FILE
   ## rm -f ${TMP_OUTPUT}
   ## ssh -i ${ENC_SRV_SECRET_KEY} ${ENC_SRV_USER}@${ENC_SRV_NAME} "${RM_TMPFILE}"

   
fi
