/*******************************************************************************
 * Copyright (c) 2012 xored software, Inc. All rights reserved. This program and the accompanying
 * materials are made available under the terms of the Eclipse Public License v1.0 which accompanies
 * this distribution, and is available at http://www.eclipse.org/legal/epl-v10.html Contributors:
 * xored software, Inc. - initial API and implementation (Yuri Strot)
 ******************************************************************************/
package com.xored.glance.internal.ui.viewers;

import org.eclipse.jface.text.ITextPresentationListener;
import org.eclipse.jface.text.TextPresentation;
import org.eclipse.jface.text.TextViewer;

import com.xored.glance.ui.sources.Match;
import com.xored.glance.ui.sources.TextChangedEvent;
import com.xored.glance.ui.utils.TextUtils;

/**
 * @author Yuri Strot
 */
public class ColoredTextViewerBlock extends TextViewerBlock implements ITextPresentationListener {

  /**
   * @param viewer
   */
  public ColoredTextViewerBlock(TextViewer viewer) {
    super(viewer);
  }

  @Override
  protected void addListeners() {
    viewer.addTextPresentationListener(this);
    super.addListeners();
  }

  @Override
  public void dispose() {
    super.dispose();
    refresh();
  }

  @Override
  protected void fireTextChanged(TextChangedEvent changedEvent) {
    matches = Match.EMPTY;
    super.fireTextChanged(changedEvent);
  }

  @Override
  protected void removeListeners() {
    super.removeListeners();
    viewer.removeTextPresentationListener(this);
  }

  public void setMatches(Match[] matches) {
    this.matches = matches;
    refresh();
  }

  public void setSelected(Match selected) {
    this.selected = selected;
    refresh();
  }

  public Match getSelected() {
    return selected;
  }

  private void refresh() {
    viewer.invalidateTextPresentation();
  }

  @Override
  public void applyTextPresentation(TextPresentation presentation) {
    TextUtils.applyStyles(presentation, matches, selected);
  }

  private Match[] matches = Match.EMPTY;
  private Match selected = null;

}
