def lambda_handler(event, context):
   message = 'Vanakkam {} !'.format(event['key1'])
   return {
       'message' : message
   }
