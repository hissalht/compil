import java.util.*;

public  class AdresseType {

    public static int getSize( String t ) {
        if (t.equals("int"))   return 1;
        if (t.equals("float")) return 2;
        System.err.println("Erreur type "+ t + " inconnu");
        return 0;
    }

    public final int adresse;
    public final String type;
    public AdresseType( int a, String t){
        this.adresse = a; // adress of initial cell on the stack to store the variable
        this.type = t;    // type of the variable
    }
}
