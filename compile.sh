cd "./d source"
dmd -O app.d types.d eval.d function.d reader.d buildins.d
status=$?
if [ $status -eq 0 ]
then
  mv ./app ../app
fi
cd ..
exit $status
