/*
 * Copyright (c) 2012, the Dart project authors.
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
package com.google.dart.tools.core.internal.model;

import com.google.dart.compiler.util.StringInterner;
import com.google.dart.engine.utilities.source.SourceRange;
import com.google.dart.tools.core.DartCore;
import com.google.dart.tools.core.completion.CompletionRequestor;
import com.google.dart.tools.core.internal.model.info.DartElementInfo;
import com.google.dart.tools.core.internal.util.MementoTokenizer;
import com.google.dart.tools.core.internal.workingcopy.DefaultWorkingCopyOwner;
import com.google.dart.tools.core.model.DartElement;
import com.google.dart.tools.core.model.DartLibrary;
import com.google.dart.tools.core.model.DartModelException;
import com.google.dart.tools.core.model.DartTypeParameter;
import com.google.dart.tools.core.model.Field;
import com.google.dart.tools.core.model.Method;
import com.google.dart.tools.core.model.Type;
import com.google.dart.tools.core.model.TypeHierarchy;
import com.google.dart.tools.core.model.TypeMember;
import com.google.dart.tools.core.workingcopy.WorkingCopyOwner;

import org.eclipse.core.runtime.IProgressMonitor;

import java.util.ArrayList;
import java.util.List;

/**
 * Instances of the class <code>DartTypeImpl</code> implement the representation of types defined in
 * compilation units.
 * 
 * @coverage dart.tools.core.model
 */
public class DartTypeImpl extends SourceReferenceImpl implements Type {
  /**
   * The name of the type.
   */
  private String name;

  /**
   * Initialize a newly created type to be defined within the given compilation unit.
   * 
   * @param parent the compilation unit containing the type
   * @param name the name of the type
   */
  public DartTypeImpl(CompilationUnitImpl parent, String name) {
    super(parent);
    this.name = StringInterner.intern(name);
  }

  @Override
  public void codeComplete(char[] snippet, int insertion, int position,
      char[][] localVariableTypeNames, char[][] localVariableNames, int[] localVariableModifiers,
      boolean isStatic, CompletionRequestor requestor) throws DartModelException {
    codeComplete(
        snippet,
        insertion,
        position,
        localVariableTypeNames,
        localVariableNames,
        localVariableModifiers,
        isStatic,
        requestor,
        DefaultWorkingCopyOwner.getInstance());
  }

  @Override
  public void codeComplete(char[] snippet, int insertion, int position,
      char[][] localVariableTypeNames, char[][] localVariableNames, int[] localVariableModifiers,
      boolean isStatic, CompletionRequestor requestor, IProgressMonitor monitor)
      throws DartModelException {
    codeComplete(
        snippet,
        insertion,
        position,
        localVariableTypeNames,
        localVariableNames,
        localVariableModifiers,
        isStatic,
        requestor,
        DefaultWorkingCopyOwner.getInstance(),
        monitor);
  }

  @Override
  public void codeComplete(char[] snippet, int insertion, int position,
      char[][] localVariableTypeNames, char[][] localVariableNames, int[] localVariableModifiers,
      boolean isStatic, CompletionRequestor requestor, WorkingCopyOwner owner)
      throws DartModelException {
    codeComplete(
        snippet,
        insertion,
        position,
        localVariableTypeNames,
        localVariableNames,
        localVariableModifiers,
        isStatic,
        requestor,
        owner,
        null);
  }

  @Override
  public void codeComplete(char[] snippet, int insertion, int position,
      char[][] localVariableTypeNames, char[][] localVariableNames, int[] localVariableModifiers,
      boolean isStatic, CompletionRequestor requestor, WorkingCopyOwner owner,
      IProgressMonitor monitor) throws DartModelException {
    if (requestor == null) {
      throw new IllegalArgumentException("Completion requestor cannot be null"); //$NON-NLS-1$
    }
    DartCore.notYetImplemented();
    // DartProjectImpl project = (DartProjectImpl) getDartProject();
    // SearchableEnvironment environment =
    // project.newSearchableNameEnvironment(owner);
    // CompletionEngine engine = new CompletionEngine(environment, requestor,
    // project.getOptions(true), project, owner, monitor);
    //
    // String source = getCompilationUnit().getSource();
    // if (source != null && insertion > -1 && insertion < source.length()) {
    //
    // char[] prefix = CharOperation.concat(source.substring(0,
    // insertion).toCharArray(), new char[]{'{'});
    // char[] suffix = CharOperation.concat(new char[]{'}'},
    // source.substring(insertion).toCharArray());
    // char[] fakeSource = CharOperation.concat(prefix, snippet, suffix);
    //
    // BasicCompilationUnit cu =
    // new BasicCompilationUnit(
    // fakeSource,
    // null,
    // getElementName(),
    // getParent());
    //
    // engine.complete(cu, prefix.length + position, prefix.length,
    // null/*extended context isn't computed*/);
    // } else {
    // engine.complete(this, snippet, position, localVariableTypeNames,
    // localVariableNames, localVariableModifiers, isStatic);
    // }
    // if (NameLookup.VERBOSE) {
    //      System.out.println(Thread.currentThread() + " TIME SPENT in NameLoopkup#seekTypesInSourcePackage: " + environment.nameLookup.timeSpentInSeekTypesInSourcePackage + "ms");  //$NON-NLS-1$ //$NON-NLS-2$
    //      System.out.println(Thread.currentThread() + " TIME SPENT in NameLoopkup#seekTypesInBinaryPackage: " + environment.nameLookup.timeSpentInSeekTypesInBinaryPackage + "ms");  //$NON-NLS-1$ //$NON-NLS-2$
    // }
  }

  @Override
  public Field createField(String contents, TypeMember sibling, boolean force,
      IProgressMonitor monitor) throws DartModelException {
    // CreateFieldOperation op = new CreateFieldOperation(this, contents,
    // force);
    // if (sibling != null) {
    // op.createBefore(sibling);
    // }
    // op.runOperation(monitor);
    // return (Field) op.getResultElements()[0];
    DartCore.notYetImplemented();
    return null;
  }

  @Override
  public Method createMethod(String contents, TypeMember sibling, boolean force,
      IProgressMonitor monitor) throws DartModelException {
    // CreateMethodOperation op = new CreateMethodOperation(this, contents,
    // force);
    // if (sibling != null) {
    // op.createBefore(sibling);
    // }
    // op.runOperation(monitor);
    // return (Method) op.getResultElements()[0];
    DartCore.notYetImplemented();
    return null;
  }

  @Override
  public boolean equals(Object o) {
    if (!(o instanceof DartTypeImpl)) {
      return false;
    }
    return super.equals(o);
  }

  @Override
  public Method[] findMethods(Method method) {
    // try {
    // return findMethods(method, getMethods());
    // } catch (DartModelException e) {
    // // if type doesn't exist, no matching method can exist
    // return null;
    // }
    DartCore.notYetImplemented();
    return null;
  }

  @Override
  public String getElementName() {
    return name;
  }

  @Override
  public int getElementType() {
    return DartElement.TYPE;
  }

  @Override
  public TypeMember[] getExistingMembers(String memberName) throws DartModelException {
    List<TypeMember> allMembers = getChildrenOfType(TypeMember.class);
    List<TypeMember> matchingMembers = new ArrayList<TypeMember>(allMembers.size());
    for (TypeMember member : allMembers) {
      if (member.getElementName().equals(memberName)) {
        matchingMembers.add(member);
      }
    }
    return matchingMembers.toArray(new TypeMember[matchingMembers.size()]);
  }

  @Override
  public Field getField(String fieldName) {
    return null;
  }

  @Override
  public Field[] getFields() throws DartModelException {
    List<Field> list = getChildrenOfType(Field.class);
    return list.toArray(new Field[list.size()]);
  }

  @Override
  public DartLibrary getLibrary() {
    return getAncestor(DartLibrary.class);
  }

  @Override
  public Method getMethod(String methodName, String[] parameterTypeSignatures) {
    return null;
  }

  @Override
  public Method[] getMethods() throws DartModelException {
    List<Method> list = getChildrenOfType(Method.class);
    return list.toArray(new Method[list.size()]);
  }

  @Override
  public SourceRange getNameRange() throws DartModelException {
    return null;
  }

  @Override
  public String getSuperclassName() throws DartModelException {

    return null;
  }

  @Override
  public String[] getSuperInterfaceNames() throws DartModelException {
    return null;
  }

  @Override
  public String[] getSupertypeNames() throws DartModelException {
    return null;
  }

  @Override
  public DartTypeParameter[] getTypeParameters() throws DartModelException {
    List<DartTypeParameter> list = getChildrenOfType(DartTypeParameter.class);
    return list.toArray(new DartTypeParameter[list.size()]);
  }

  @Override
  @Deprecated
  public String getTypeQualifiedName(char separatorChar) {
    // TODO(devoncarew): remove this method
    return getElementName();
  }

  @Override
  public boolean isAbstract() throws DartModelException {
    if (isInterface()) {
      return true;
    }
    for (Method m : getMethods()) {
      if (m.isAbstract()) {
        return true;
      }
    }
    return false;
  }

  @Override
  public boolean isClass() throws DartModelException {
    return false;
  }

  @Override
  public boolean isInterface() throws DartModelException {
    return false;
  }

  @Override
  public TypeHierarchy newSupertypeHierarchy(IProgressMonitor progressMonitor)
      throws DartModelException {
    // TODO(devoncarew): this method needs to be implemented
    DartCore.notYetImplemented();
    return null;
  }

  @Override
  protected DartElementInfo createElementInfo() {
    return null;
  }

  @Override
  protected DartElement getHandleFromMemento(String token, MementoTokenizer tokenizer,
      WorkingCopyOwner owner) {

    return null;
  }

  @Override
  protected char getHandleMementoDelimiter() {
    return MEMENTO_DELIMITER_TYPE;
  }
}
