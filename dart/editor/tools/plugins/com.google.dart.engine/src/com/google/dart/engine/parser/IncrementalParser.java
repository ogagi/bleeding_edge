/*
 * Copyright (c) 2013, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.engine.parser;

import com.google.dart.engine.ast.ASTNode;
import com.google.dart.engine.ast.visitor.NodeLocator;
import com.google.dart.engine.error.AnalysisErrorListener;
import com.google.dart.engine.scanner.Token;
import com.google.dart.engine.scanner.TokenType;
import com.google.dart.engine.source.Source;
import com.google.dart.engine.utilities.ast.IncrementalASTCloner;
import com.google.dart.engine.utilities.collection.TokenMap;

/**
 * Instances of the class {@code IncrementalParser} re-parse a single AST structure within a larger
 * AST structure.
 */
public class IncrementalParser {
  /**
   * The source being parsed.
   */
  private Source source;

  /**
   * A map from old tokens to new tokens used during the cloning process.
   */
  private TokenMap tokenMap;

  /**
   * The error listener that will be informed of any errors that are found during the parse.
   */
  private AnalysisErrorListener errorListener;

  /**
   * Initialize a newly created incremental parser to parse a portion of the content of the given
   * source.
   * 
   * @param source the source being parsed
   * @param tokenMap a map from old tokens to new tokens used during the cloning process
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during the parse
   */
  public IncrementalParser(Source source, TokenMap tokenMap, AnalysisErrorListener errorListener) {
    this.source = source;
    this.tokenMap = tokenMap;
    this.errorListener = errorListener;
  }

  /**
   * Given a range of tokens that were re-scanned, re-parse the minimimum number of tokens to
   * produce a consistent AST structure. The range is represented by the first and last tokens in
   * the range. The tokens are assumed to be contained in the same token stream.
   * 
   * @param firstToken the first token in the range of tokens that were re-scanned
   * @param lastToken the last token in the range of tokens that were re-scanned
   * @param originalStart the offset in the original source of the first character that was modified
   * @param originalEnd the offset in the original source of the last character that was modified
   */
  @SuppressWarnings("unchecked")
  public <E extends ASTNode> E reparse(E originalStructure, Token firstToken, Token lastToken,
      int originalStart, int originalEnd) {
    //
    // Find the smallest AST node that encompasses the range of re-scanned tokens.
    //
    ASTNode oldNode;
    if (originalEnd < originalStart) {
      oldNode = new NodeLocator(originalStart).searchWithin(originalStructure);
    } else {
      oldNode = new NodeLocator(originalStart, originalEnd).searchWithin(originalStructure);
    }
    //
    // Find the token at which parsing is to begin.
    //
    int originalOffset = oldNode.getOffset();
    Token parseToken = findTokenAt(firstToken, originalOffset);
    if (parseToken == null) {
      return null;
    }
    //
    // Parse the appropriate AST structure starting at the appropriate place.
    //
    Parser parser = new Parser(source, errorListener);
    parser.setCurrentToken(parseToken);
    ASTNode newNode = null;
    while (newNode == null) {
      ASTNode parent = oldNode.getParent();
      if (parent == null) {
        parseToken = findFirstToken(parseToken);
        parser.setCurrentToken(parseToken);
        return (E) parser.parseCompilationUnit();
      }
      try {
        IncrementalParseDispatcher dispatcher = new IncrementalParseDispatcher(parser, oldNode);
        newNode = parent.accept(dispatcher);
      } catch (InsufficientContextException exception) {
        oldNode = parent;
        originalOffset = oldNode.getOffset();
        parseToken = findTokenAt(parseToken, originalOffset);
        parser.setCurrentToken(parseToken);
      } catch (Exception exception) {
        return null;
      }
    }
    //
    // Validate that the new node can replace the old node.
    //
    if (newNode.getOffset() != originalOffset) {
      // TODO(brianwilkerson) Figure out how to test whether the new node covers all of and only the
      // appropriate tokens. Note that this is made more difficult by the possibility of synthetic
      // tokens, which are not added to the token stream.
      return null;
    }
    //
    // Replace the old node with the new node in a copy of the original AST structure.
    //
    if (oldNode == originalStructure) {
      // We ended up re-parsing the whole structure, so there's no need for a copy.
      return (E) newNode;
    }
    IncrementalASTCloner cloner = new IncrementalASTCloner(oldNode, newNode, tokenMap);
    return (E) originalStructure.accept(cloner);
  }

  /**
   * Return the first (non-EOF) token in the token stream containing the given token.
   * 
   * @param firstToken the token from which the search is to begin
   * @return the first token in the token stream containing the given token
   */
  private Token findFirstToken(Token firstToken) {
    while (firstToken.getType() != TokenType.EOF) {
      firstToken = firstToken.getPrevious();
    }
    return firstToken.getNext();
  }

  /**
   * Find the token at or before the given token with the given offset, or {@code null} if there is
   * no such token.
   * 
   * @param firstToken the token from which the search is to begin
   * @param offset the offset of the token to be returned
   * @return the token with the given offset
   */
  private Token findTokenAt(Token firstToken, int offset) {
    while (firstToken.getOffset() > offset && firstToken.getType() != TokenType.EOF) {
      firstToken = firstToken.getPrevious();
    }
    if (firstToken.getOffset() == offset) {
      return firstToken;
    }
    return null;
  }
}
