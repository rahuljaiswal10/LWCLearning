// This class has MessageId or Log Code range from 6000 - 6999.
public class CustomRuleEvaluationUtil {

    // Allowed operations in a Evaluation String when defining a Queue(like we define in Workflow rule criteria).
    private final static String OR_OP = 'OR';
    public final static String AND_OP = 'AND';
    private final static String LEFT_PARENTHESIS = '(';
    private final static String RIGHT_PARENTHESIS = ')';

    private static CustomRuleEvaluationUtil INSTANCE;

    private Map<String, Integer> reservedKeywordToPriorityMap = null;

    private CustomRuleEvaluationUtil(){
        initialize();
    }

    private void initialize() {
        reservedKeywordToPriorityMap = new Map<String, Integer>();
        reservedKeywordToPriorityMap.put(AND_OP, 3);
        reservedKeywordToPriorityMap.put(OR_OP, 2);
        reservedKeywordToPriorityMap.put(LEFT_PARENTHESIS, 1);
        reservedKeywordToPriorityMap.put(RIGHT_PARENTHESIS, 1);
    }

    public static CustomRuleEvaluationUtil getInstance(){
        if (INSTANCE == null){
            INSTANCE = new CustomRuleEvaluationUtil();
        }
        return INSTANCE;
    }  

    /**
     * It converts the String expressions like A OR ( B AND C ) in
     * Postfix notations.
     * Output Example: [A, B, C, AND, OR]
     **/
    public List<String> convertToPostfixNotation(String evaluationRule) {
        List<String> operatorStack = new List<String>();
        List<String> operandStack = new List<String>();
        List<String> resultedExp = new List<String>();

        boolean isOperator = false;
        boolean isOperand = false;

        String token = '';
        List<String> chars = evaluationRule.split('');
        
        // Add closing parenthesis to the chars stack.
        chars.add(')');
        // Add opening parenthesis to the operatorStack stack.
        operatorStack.add('(');
        Integer expLength = chars.size();

        for (Integer charIndex = 0; charIndex < expLength; charIndex++) {
            String ch = chars.get(charIndex);
            if (ch.isNumeric()) {
                isOperand = true;
                token += ch;
            } else if (ch.isAlpha()) {
                isOperator = true;
                token += ch;
            } else if (ch.equals('(')) {// For exp like A + (C * D); we are at ( just before C.
                if (isOperator) {
                    isOperator = false;
                    // Validates if it is a operator or not.
                    if (!reservedKeywordToPriorityMap.containsKey(token)) {
                        System.debug('Unexpected token: ' + token);
                    }
                    // If operator is encountered then remove all other operators from operatorStack
                    //which has greater Priority than this one. Token is the previous operator before ( is encountered.
                    while(!operatorStack.isEmpty() && reservedKeywordToPriorityMap.get(operatorStack.get(operatorStack.size() - 1)) > reservedKeywordToPriorityMap.get(token)) {
                        resultedExp.add(operatorStack.remove(operatorStack.size() - 1));
                    }
                    // Finally add that previous token to the head of the list.
                    operatorStack.add(token);
                    token = '';
                } else if (isOperand) {
                    isOperand = false;
                    resultedExp.add(token);
                    token = '';
                }
                // Add operator with low priority to Operator Stack.
                operatorStack.add('(');
            } else if (ch.equals(')')) {
                if (isOperand) {
                    isOperand = false;
                    resultedExp.add(token);
                    token = '';
                }

                while(!operatorStack.isEmpty() && operatorStack.get(operatorStack.size() - 1) != '(') {
                    String operator = operatorStack.remove(operatorStack.size() - 1);
                    resultedExp.add(operator);
                }
                //After this remove '(' from the stack.
                String operator = operatorStack.remove(operatorStack.size() - 1);
            } else if (!ch.isNumeric() && isOperand) { // space is encountered.
                isOperand = false;
                operandStack.add(token);
                resultedExp.add(token);
                token = '';
            } else if (!ch.isAlpha() && isOperator) {
                isOperator = false;

                // Validates if it is a operator or not.
                if (!reservedKeywordToPriorityMap.containsKey(token)) {
                    System.debug('Unexpected token: ' + token);
                }

                while(!operatorStack.isEmpty() && reservedKeywordToPriorityMap.get(operatorStack.get(operatorStack.size() - 1)) > reservedKeywordToPriorityMap.get(token)) {
                    String operator = operatorStack.remove(operatorStack.size() - 1);
                    resultedExp.add(operator);
                }
                // Add operator with low priority to Operator Stack.
                operatorStack.add(token);

                token = '';
            } else if (ch.equals(' ')) {
            }
            System.debug('chars -> '+chars);
            System.debug('operatorStack -> '+operatorStack);
        }
        //space didn't appear and hence we couldn't catch operator or operand
        if(token != '') {
            System.debug('Invalid format');
        }

        

        return resultedExp;
    }

    private boolean evaluatePostfixExpression(List<String> expression, Map<Integer, boolean> criateriaNumberToValidationMap) {
        
        
        List<boolean> operands = new List<boolean>();
        for (String token : expression) {
            // It means its an Operand.
            if (!reservedKeywordToPriorityMap.containsKey(token)) {
                operands.add(criateriaNumberToValidationMap.get(Integer.valueOf(token)));
            } else {// It means its an Operator.

                boolean result = performOperation(token, operands);
                operands.add(result);
            }
        }
        // In last only one element will remain in the list that is the final result.
        return operands.get(operands.size() - 1);
    }

    /**
    * Checks if evaluation rule is balanced with respect to paranthesis
    *
    */
    private boolean checkBalancedParanthesis(String evaluationRule) {
        List<String> stack = new List<String>();
        for(Integer i = 0; i < evaluationRule.length(); i++) {
            String ch = evaluationRule.substring(i, i+1);
            if(ch == '(') {
                stack.add(ch);
            } else if(ch == ')') {
                if(!stack.isEmpty()) {
                    String stackChar = stack.remove(stack.size() - 1);
                } else {
                    return false;
                }
            }
        }
        if(stack.isEmpty()) {
            return true;
        }
        return false;
    }

    /**
     * Checks and confirms if the Criteria Rule is evaluated to True or False.
     * 1 OR(2 AND 3) - Valid Rule.
     * 1 OR (2 AND 3) - Valid Rule.
     * 1 OR 2 AND 3 - Valid Rule.
     * 1 OR (2 AND 3 AND (4 OR 5)) - Valid Rule.
     * 1OR (2 AND 3) - Invalid Rule.
     *
     **/
    public boolean isEvaluationRuleExpressionValid(String evaluationRule, Integer criteriaListSize) {
        
        
        

        if(!checkBalancedParanthesis(evaluationRule)) {
            return false;
        }

        String token = '';
        List<String> tokens = evaluationRule.replace(')', ' ').replace('(', ' ').split(' ');
        Integer expLength = tokens.size();

        for (Integer charIndex = 0; charIndex < expLength; charIndex++) {

            token = tokens.get(charIndex).trim();
            if(!String.isEmpty(token)) {
        
                if (token.isAlpha() && !reservedKeywordToPriorityMap.containsKey(token)) {
                    System.debug('Invalid Operator: ' + token);
                } else if (token.isNumeric() && Integer.valueOf(token) > criteriaListSize
                    || token.isNumeric() && Integer.valueOf(token) < 1) {
                    System.debug('Invalid Criteria Number: ' + token);
                } else if (!token.isAlpha() && !token.isNumeric()) {
                    System.debug('Invalid Token encountered: ' + token);
                }
            }
        }

        return isEvaluationRuleValid(evaluationRule);
    }

    public boolean isEvaluationRuleValid(String evaluationRule) {
        List<String> postfixExpression = convertToPostfixNotation(evaluationRule);
        return validatePostfixExpression(postfixExpression);
    }

    private boolean validatePostfixExpression(List<String> expression) {
        

        List<boolean> operands = new List<boolean>();
        for (String token : expression) {
            // It means its an Operand.
            if (!reservedKeywordToPriorityMap.containsKey(token)) {
                operands.add(true);
            } else {// It means its an Operator.
                boolean result = performOperation(token, operands);
                operands.add(result);
            }
        }

        if (operands.size() > 1) {
            return false;
        }
        // In last only one element will remain in the list that is the final result.
        return operands.get(operands.size() - 1);
    }

    private boolean performOperation(String opName, List<boolean> operands) {
        
        

        Boolean operandsPresent = true;
        boolean topMost;
        boolean secondMost;
        if(operands.isEmpty()) {
            operandsPresent = false;
        } else {
            topMost = operands.remove(operands.size() - 1);
        }
        if(operands.isEmpty()) {
            operandsPresent = false;
        } else {
            secondMost = operands.remove(operands.size() - 1);
        }
        if(!operandsPresent) {
            System.debug('Invalid format');
        }
        if (opName.equalsIgnoreCase(AND_OP)) {
            if (topMost && secondMost) {
                return true;
            } else {
                return false;
            }
        } else if (opName.equalsIgnoreCase(OR_OP)) {
            if (topMost || secondMost) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    public Boolean evaluateRuleExpression(String ruleExpr, Map<Integer, Boolean> criateriaNumberToResultMap){
        List<String> postfixExpression = convertToPostfixNotation(ruleExpr);
        return evaluatePostfixExpression(postfixExpression, criateriaNumberToResultMap);
    }
    
    /**
     * It converts the String expressions like 1 OR ( 2 AND 3 ) in
     * token set.
     * Output Example: [1, 2, 3]
     **/
    public Set<Integer> getDistinctSetOfCritSeqFromEvalExpression(String evalExpression){
        
        if(evalExpression != null){
            Set<Integer> setCriteriaSeq = new Set<Integer>();
            List<String> listCriteriaTokens = convertToPostfixNotation(evalExpression);
    
            for(String criteriaTokens : listCriteriaTokens){
                if(!OR_OP.equalsIgnoreCase(criteriaTokens) && !AND_OP.equalsIgnoreCase(criteriaTokens)){
                    setCriteriaSeq.add(Integer.valueOf(criteriaTokens));
                }
            }
    
            return setCriteriaSeq;
        }
        else{
            return null;
        }
    }
}