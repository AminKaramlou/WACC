#ifndef CODE_GENERATION_VISITOR_HH
#define CODE_GENERATION_VISITOR_HH
#include "ast-node-visitor.hh"

class CodeGenVisitor : public AstNodeVisitor {
public:
  const int MAX_REG_NUMBER = 16;
  CodeGenVisitor(std::ostream *stream);
  ~CodeGenVisitor();

  void visit(ASTnode *node);
  void visit(Program *node);
  void visit(AssignRhs *node);
  void visit(AssignLhs *node);
  void visit(Expression *node);
  void visit(StatSeq *node);
  void visit(FunctionDecList *node);
  void visit(IntegerType *node);
  void visit(BoolType *node);
  void visit(CharType *node);
  void visit(StringType *node);
  void visit(ArrayType *node);
  void visit(PairType *node);
  void visit(VariableDeclaration *node);
  void visit(FunctionDeclaration *node);
  void visit(FunctionCall *node);
  void visit(Assignment *node);
  void visit(FreeStatement *node);
  void visit(ReturnStatement *node);
  void visit(ExitStatement *node);
  void visit(BeginStatement *node);
  void visit(IfStatement *node);
  void visit(WhileStatement *node);
  void visit(ReadStatement *node);
  std::string visitAndPrintReg(Expression *node);
  void CodeGenVisitor::print(IntTypeId type);
  void CodeGenVisitor::print(StringTypeId type);
  void CodeGenVisitor::print(CharTypeId type);
  void visit(PrintStatement *node);
  void visit(PrintlnStatement *node);
  void visit(Number *node);
  void visit(Boolean *node);
  void visit(Char *node);
  void visit(String *node);
  void visit(Null *node);
  void visit(BinaryOperator *node);
  void visit(Identifier *node);
  void visit(ArrayElem *node);
  void visit(PairElem *node);
  void visit(ArrayLiter *node);
  void visit(NewPair *node);
  void visit(UnaryOperator *node);

  void defineLabel(String label);
  
  void populateRegMap();
  std::string getAvailableRegister();
  void freeRegister(std::string reg);
  

private:
  std::ostream *output;
  std::map<std::string, bool> *regTable;
  int labelNum   = 0;
  int messageNum = 0;
};


#endif // ! CODE_GENERATION_VISITOR_HH
