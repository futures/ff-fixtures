#!/bin/bash

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "ERROR # ${1} : ${2}"
     benchmark
     exit 1
  fi
}


CORPUS_NAME=thread${THREAD_ID-0}
PROCESSING_DIR=govdocs
BAGIT_PY_CMD=${BAGIT_PY-./bagit.py}

command -v curl >/dev/null || { echo "curl command not found, aborting"; exit 1; }
command -v python >/dev/null || { echo "python command not found, aborting"; exit 1; }
command -v unzip >/dev/null || { echo "unzip command not found, aborting"; exit 1; }

if [ ! -f $BAGIT_PY_CMD ]; then
	echo "bagit.py command not found, aborting."
	echo "Hint: try calling this script with an explicit BAGIT_PY, e.g.:"
	echo "$ BAGIT_PY=./path/to/bagit.py $0"; exit 1;
fi

touch .gitignore
mkdir ${PROCESSING_DIR}

if [ -f ${PROCESSING_DIR}/processed_${CORPUS_NAME} ]; then
  echo "Already processed govdocs ${CORPUS_NAME}, aborting"
  exit 1;
fi

if [ -f ${PROCESSING_DIR}/${CORPUS_NAME}.zip ]; then
  echo " (Found existing corpus; using it)"
else
  echo " == Downloading Corpus"
  curl -o ${PROCESSING_DIR}/${CORPUS_NAME}.zip http://digitalcorpora.org/corp/nps/files/govdocs1/zipfiles/${CORPUS_NAME}.zip
  check_errs $? "download failed"
fi

echo " == Extracting Corpus"
unzip ${PROCESSING_DIR}/${CORPUS_NAME}.zip -d ${PROCESSING_DIR}
check_errs $? "unzip failed"

chmod -R a+w ${PROCESSING_DIR}

echo " == Moving bagged objects"
for i in $( find ${PROCESSING_DIR} -maxdepth 1 -type d | grep -v "^govdocs$"); do
python $BAGIT_PY_CMD --contact-name 'Digital Corpora' $i
check_errs $? "bagging failed"
  mv $i objects

check_errs $? "moving object failed"
done

touch ${PROCESSING_DIR}/processed_${CORPUS_NAME}
