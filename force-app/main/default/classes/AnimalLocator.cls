public class AnimalLocator {
    public static String getAnimalNameById(Integer id){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://th-apex-http-callout.herokuapp.com/animals/'+Id);
        request.setMethod('GET');
        System.debug('>>>>>>>'+id);
        HttpResponse response = http.send(request);
      	Object animals;
        String returnValue;
       	System.debug(response);
        System.debug(response.getBody());
        System.debug(response.getStatusCode());
        // If the request is successful, parse the JSON response
        if (response.getStatusCode() == 200) {
            JSON2Apex1 obj = JSON2Apex1.parse(response.getBody());
            System.debug(obj.Animal.Id);
        	System.debug(obj.animal);
        }
        
        return returnValue;
    }
}