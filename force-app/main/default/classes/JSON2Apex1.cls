public class JSON2Apex1 {

    public Animal animal;

    public class Animal {
        public Integer id;
        public String name;
        public String eats;
        public String says;
    }

    
    public static JSON2Apex1 parse(String json) {
        return (JSON2Apex1) System.JSON.deserialize(json, JSON2Apex1.class);
    }
}