if [ "$1" == "--update" ]; then
    echo "updating stack.."
    aws cloudformation update-stack --stack-name Logan-AnalysisC5A --template-body file://templatec5a.yaml --capabilities CAPABILITY_NAMED_IAM
else
    aws cloudformation create-stack --stack-name Logan-AnalysisC5A --template-body file://templatec5a.yaml --capabilities CAPABILITY_NAMED_IAM
fi
