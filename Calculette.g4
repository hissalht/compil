grammar Calculette;

@parser::members {

    private TablesSymboles tablesSymboles = new TablesSymboles();
    private int _label = 0;

    private int nextLabel() { return _label++; }

    private int evalexpr(int x, String op, int y){
        if(op.equals("*")){
            return x * y;
        }else if(op.equals("+")){
            return x + y;
        }else if(op.equals("/")){
            return x / y;
        }else if(op.equals("-")){
            return x - y;
        }else {
            System.err.println("Opérateur inconnu : " + op);
            throw new IllegalArgumentException("Opérateur inconnu");
        }
    }

    private String getOperationCode(String op){
        if(op.equals("*")){
            return "MUL\n";
        }
        if(op.equals("/")){
            return "DIV\n";
        }
        if(op.equals("+")){
            return "ADD\n";
        }
        if(op.equals("-")){
            return "SUB\n";
        }else{
            System.err.println("Opérateur inconnu : " + op);
            throw new IllegalArgumentException("Opérateur inconnu");
        }
    }


    private String getOperationCodeFloat(String op){
        if(op.equals("*")){
            return "FMUL\n";
        }
        if(op.equals("/")){
            return "FDIV\n";
        }
        if(op.equals("+")){
            return "FADD\n";
        }
        if(op.equals("-")){
            return "FSUB\n";
        }else{
            System.err.println("Opérateur inconnu : " + op);
            throw new IllegalArgumentException("Opérateur inconnu");
        }
    }

    private String getRelationCode(String op){
        switch(op){
            case "==":
                return "EQUAL\n";
            case "!=":
            case "<>":
                return "NEQ\n";
            case "<":
                return "INF\n";
            case ">":
                return "SUP\n";
            case "<=":
                return "INFEQ\n";
            case ">=":
                return "SUPEQ\n";
            default:
                System.err.println("Opérateur inconnu : " + op);
                throw new IllegalArgumentException("Opérateur inconnu");
        }
    }

    private String getRelationCodeFloat(String op){
        switch(op){
            case "==":
                return "FEQUAL\n";
            case "!=":
            case "<>":
                return "FNEQ\n";
            case "<":
                return "FINF\n";
            case ">":
                return "FSUP\n";
            case "<=":
                return "FINFEQ\n";
            case ">=":
                return "FSUPEQ\n";
            default:
                System.err.println("Opérateur inconnu : " + op);
                throw new IllegalArgumentException("Opérateur inconnu");
        }
    }

    private void typeIncompatibleError(){
        System.err.println("ERREUR : Opération sur des types différents");
        /*throw new RuntimeException("Type incomaptible");*/
    }

    private void typeIncorrectError(){
        System.err.println("ERREUR : Type incorrect");
        throw new RuntimeException("Type incorrect");
    }

}



start
    /*: expr EOF {System.out.println($expr.code + "HALT\n");};*/
    : calcul EOF;



expr returns [String code, String type]
    // arithmetics
    : '(' a=expr ')' { $code = $a.code; $type = $a.type;}
    | '-' a=expr { $code = "PUSHI 0\n" + $a.code + "SUB\n"; $type = $a.type;}
    | a=expr op=('*'|'/') b=expr
      {
        if(!$a.type.equals($b.type)){
            // a et b de types differents -> erreur
            typeIncompatibleError();
        }
        if($a.type.equals("int")){
            $code = $a.code + $b.code + getOperationCode($op.text);
        }else{
            $code = $a.code + $b.code + getOperationCodeFloat($op.text);
        }
        $type = $a.type;
      }
    | a=expr op=('+'|'-') b=expr
      {
        if(!$a.type.equals($b.type))
            typeIncompatibleError();
        if($a.type.equals("int")){
            $code = $a.code + $b.code + getOperationCode($op.text);
        }else{
            $code = $a.code + $b.code + getOperationCodeFloat($op.text);
        }
        $type = $a.type;
      }

    //relation == != <= >= < >
    | a=expr op=REL_OP b=expr
      {
        if(!$a.type.equals($b.type))
            typeIncompatibleError();
        $code = $a.code + $b.code;
        if($a.type.equals("int"))
            $code += getRelationCode($op.text);
        else
            $code += getRelationCodeFloat($op.text);
        $type = "int";
      }

    //boolean operations
    | NOT a=expr
      {
        if(!$a.type.equals("int"))
            typeIncorrectError(); // operation booléenne uniquement sur entier
        int false_true = nextLabel();
        int after = nextLabel();
        $code = $a.code;
        $code += "JUMPF " + false_true + "\n";
        $code += "PUSHI 0\n";
        $code += "JUMP " + after + "\n";
        $code += "  LABEL " + false_true + "\n";
        $code += "PUSHI 1\n";
        $code += "  LABEL " + after + "\n";
        $type = "int";
      }
    | a=expr AND b=expr
      {
        if(!$a.type.equals("int"))
            typeIncorrectError(); // operation booléenne uniquement sur entier
        int left = nextLabel();
        int right = nextLabel();
        int end = nextLabel();
        $code = $a.code;
        $code += $b.code;
        $code += "JUMPF " + left + "\n";
        $code += "JUMPF " + right + "\n";
        $code += "PUSHI 1\n";
        $code += "JUMP " + end + "\n";
        $code += "  LABEL " + left + "\n";
        $code += "POP\n";
        $code += "PUSHI 0\n";
        $code += "JUMP " + end + "\n";
        $code += "  LABEL " + right + "\n";
        $code += "PUSHI 0\n";
        $code += "  LABEL " + end + "\n";
        $type = "int";
      }
    | a=expr OR b=expr
      {
        if(!$a.type.equals("int"))
            typeIncorrectError(); // operation booléenne uniquement sur entier
        int label = nextLabel();
        $code = $a.code;
        $code += $b.code;
        $code += "JUMPF " + label + "\n";
        $code += "POP\nPUSHI 1\n  LABEL " + label + "\n";
        $type = "int";
      }

    //values
    | FLOTTANT {$code = "PUSHF " + $FLOTTANT.text + "\n"; $type = "float";}
    | ENTIER   {$code = "PUSHI " + $ENTIER.text + "\n"; $type = "int";}
    | TRUE {$code = "PUSHI 1\n"; $type = "int";}
    | FALSE {$code = "PUSHI 0\n"; $type = "int";}
    | IDENTIFIANT
      {
        /*AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);*/
        /*$code = "PUSHG " + at.adresse + "\n";*/

        AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
        $type = at.type;
        if($type.equals("int")){
            $code = "PUSHL " + at.adresse + "\n";
        }else if($type.equals("float")){
            $code = "PUSHL " + at.adresse + "\n" +      //première partie du flottant
                    "PUSHL " + (at.adresse+1) + "\n";   //deuxième partie du flottant
        }
      }
    ;

decl returns [String code]
    : TYPE IDENTIFIANT finInstruction
      {
        tablesSymboles.putVar($IDENTIFIANT.text, $TYPE.text);
        if($IDENTIFIANT.text.equals("int"))
            $code = "PUSHI 0\n";
        else
            $code = "PUSHF 0\n";
      }
    | TYPE IDENTIFIANT '=' expr finInstruction
      {
        /*tablesSymboles.putVar($IDENTIFIANT.text, $TYPE.text);*/
        /*AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);*/
        /*$code = "PUSHI 0\n" + $expr.code + "STOREG " + at.adresse + "\n";*/
        if(!$TYPE.text.equals($expr.type)){
            //erreur de typage
            typeIncompatibleError();
        }
        tablesSymboles.putVar($IDENTIFIANT.text, $TYPE.text);
        AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
        if($TYPE.text.equals("int")){
            $code = "PUSHI 0\n" + $expr.code + "STOREG " + at.adresse + "\n";
        }else{
            $code = "PUSHF 0.0\n" + $expr.code + "STOREG " + (at.adresse+1) + "\n" //stock la partie droite
                                               + "STOREG " + at.adresse + "\n"; //stock la partie gauche
        }
      }
    ;

instruction returns [String code]
    : expr finInstruction
      {
        $code = $expr.code + "POP\n";
        //evaluation de l'expression et supression immédiate de la valeur
      }
    | assignation finInstruction
      {
        $code = $assignation.code;
      }
    | entree finInstruction
      {
        $code = $entree.code;
      }
    | sortie finInstruction
      {
        $code = $sortie.code;
      }
    | boucle
      {
        $code = $boucle.code;
      }
    | finInstruction
      {
        $code="";
      }
    ;

finInstruction returns [String code]
    : NEWLINE ;

assignation returns [String code]
    : IDENTIFIANT '=' expr
      {
        AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
        $code = $expr.code + "STOREG " + at.adresse + "\n";
      }
    ;

// x <<
// récupère une valeur sur l'entrée standard
entree returns [String code]
    : IDENTIFIANT INPUT
      {
        AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
        $code = "READ\nSTOREG " + at.adresse + "\n";
      }
    ;

// x >>
// affiche la valeur de x
sortie returns [String code]
    : IDENTIFIANT OUTPUT
      {
        AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
        if(at.type.equals("int")){
            $code = "PUSHG " + at.adresse + "\nWRITE\nPOP\n";
        }else{
            $code = "PUSHG " + at.adresse + "\n" +
                    "PUSHG " + (at.adresse+1) + "\n" +
                    "WRITEF\nPOP\nPOP\n";
        }
      }
    ;


boucle returns [String code]
    : WHILE '(' /*condition*/ expr ')' instruction
      {
        if(!$expr.type.equals("int"))
            typeIncorrectError(); // condition uniquement sur entier
        int start = nextLabel();
        int end = nextLabel();
        $code = "  LABEL " + start + "\n";
        $code += $expr.code;
        $code += "JUMPF " + end + "\n";
        $code += $instruction.code;
        $code += "JUMP " + start + "\n";
        $code += "  LABEL " + end + "\n";
      }
    ;

/*condition returns [String code]*/
    /*: '(' condition ')' { $code = $condition.code; }*/
    /*| TRUE  { $code = "PUSHI 1\n"; }*/
    /*| FALSE { $code = "PUSHI 0\n"; }*/
    /*| a=expr op=REL_OP b=expr*/
      /*{*/
        /*$code = $a.code + $b.code;*/
        /*$code += getRelationCode($op.text);*/
      /*}*/
    /*;*/


calcul returns [String code]
@init{ $code = new String(); }
@after{ System.out.println($code); }
    : (decl { $code += $decl.code; })*

      {$code += "#fin declarations\n";}

      NEWLINE*

      (instruction { $code += $instruction.code; } )*

      {
        $code += "#pile cleaning\n";
        for(int i = 0 ; i < tablesSymboles.getTailleTableGlobale() ; i++){
            $code += "POP\n";
        }
        $code += "HALT\n";
      }
    ;


// lexer
TYPE : 'int' | 'float';
WHILE : 'while';
TRUE : 'true';
FALSE : 'false';
AND : 'and';
OR : 'or';
NOT : 'not';
REL_OP : '==' | '!=' | '<>' | '<' | '>' | '<=' | '>=';
NEWLINE : '\r'? '\n';
IDENTIFIANT : ('a'..'z'|'A'..'Z')('a'..'z'|'A'..'Z'|'0'..'9')*;
FLOTTANT : (('0'..'9')+ '.' ('0'..'9')*);
ENTIER : ('0'..'9')+ ;
INPUT : '<<';
OUTPUT : '>>';

WS : (' '|'\t')+ -> skip ;
UNMATCH : . -> skip ;
