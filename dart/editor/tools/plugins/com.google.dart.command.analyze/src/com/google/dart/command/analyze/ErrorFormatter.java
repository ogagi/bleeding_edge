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

package com.google.dart.command.analyze;

import com.google.dart.engine.error.AnalysisError;
import com.google.dart.engine.error.ErrorSeverity;
import com.google.dart.engine.error.ErrorType;
import com.google.dart.engine.scanner.CharSequenceReader;
import com.google.dart.engine.scanner.Scanner;
import com.google.dart.engine.source.Source;
import com.google.dart.engine.utilities.source.LineInfo;
import com.google.dart.engine.utilities.source.LineInfo.Location;

import java.io.PrintStream;
import java.nio.CharBuffer;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Format a set of errors. The two format options are a user consumable format and a machine
 * consumable format.
 */
public class ErrorFormatter {

  static class AnalysisErrorComparator implements Comparator<AnalysisError> {
    @Override
    public int compare(AnalysisError error1, AnalysisError error2) {
      int compare = error1.getErrorCode().getErrorSeverity().compareTo(
          error2.getErrorCode().getErrorSeverity());

      if (compare != 0) {
        return -1 * compare;
      }

      compare = error1.getSource().getFullName().compareToIgnoreCase(
          error2.getSource().getFullName());

      if (compare != 0) {
        return compare;
      }

      return error1.getOffset() - error2.getOffset();
    }
  }

  private static String escapePipe(String input) {
    StringBuilder result = new StringBuilder();
    for (char c : input.toCharArray()) {
      if (c == '\\' || c == '|') {
        result.append('\\');
      }
      result.append(c);
    }
    return result.toString();
  }

  private static String pluralize(String word, int count) {
    if (count == 1) {
      return word;
    } else {
      return word + "s";
    }
  }

  private PrintStream out;

  private AnalyzerOptions options;

  private Map<Source, LineInfo> lineInfoMap = new HashMap<Source, LineInfo>();

  public ErrorFormatter(PrintStream out, AnalyzerOptions options) {
    this.out = out;
    this.options = options;
  }

  public void formatError(AnalysisError error) {
    Source source = error.getSource();
    Location location = getLocation(source, error.getOffset());
    int length = error.getLength();

    if (options.getMachineFormat()) {
      out.println(String.format(
          "%s|%s|%s|%s|%d|%d|%d|%s",
          getMachineCode(error.getErrorCode().getErrorSeverity(), options.getWarningsAreFatal()),
          escapePipe(error.getErrorCode().getType().toString()),
          escapePipe(error.getErrorCode().toString()),
          escapePipe(source.getFullName()),
          location.getLineNumber(),
          location.getColumnNumber(),
          length,
          escapePipe(error.getMessage())));
    } else {
      String errorType = error.getErrorCode().getErrorSeverity().getDisplayName();

      if (error.getErrorCode().getType() == ErrorType.HINT) {
        errorType = error.getErrorCode().getType().getDisplayName();
      }

      // [warning] 'foo' is not a method or function (/Users/devoncarew/tmp/foo.dart, line 1, col 2)
      out.println(String.format("[%s] %s (%s, line %d, col %d)", //
          errorType,
          error.getMessage(),
          source.getFullName(),
          location.getLineNumber(),
          location.getColumnNumber()));
    }
  }

  public void formatErrors(List<AnalysisError> errors) {
    // Sort by severity, file path, and file location.
    Collections.sort(errors, new AnalysisErrorComparator());

    int errorCount = 0;
    int warnCount = 0;
    int hintCount = 0;

    for (AnalysisError error : errors) {
      ErrorSeverity severity = error.getErrorCode().getErrorSeverity();
      if (severity.equals(ErrorSeverity.ERROR)) {
        errorCount++;
      } else if (severity.equals(ErrorSeverity.WARNING)) {
        if (options.getWarningsAreFatal()) {
          errorCount++;
        } else {
          if (error.getErrorCode().getType() == ErrorType.HINT) {
            hintCount++;
          } else {
            warnCount++;
          }
        }
      } else if (severity.equals(ErrorSeverity.INFO)) {
        hintCount++;
      }

      formatError(error);
    }

    if (!options.getMachineFormat()) {
      StringBuffer buf = new StringBuffer();

      if (errorCount != 0) {
        buf.append(String.format("%d %s", errorCount, pluralize("error", errorCount)));
      }

      if (warnCount != 0) {
        if (buf.length() > 0) {
          if (hintCount == 0) {
            buf.append(" and ");
          } else {
            buf.append(", ");
          }
        }
        buf.append(String.format("%d %s", warnCount, pluralize("warning", warnCount)));
      }

      if (hintCount != 0) {
        if (buf.length() > 0) {
          buf.append(", and ");
        }
        buf.append(String.format("%d %s", hintCount, pluralize("hint", hintCount)));
      }

      if (buf.length() != 0) {
        buf.append(" found.");
      } else {
        buf.append("No issues found");
      }

      out.println(buf.toString());
    }
  }

  public void startAnalysis() {
    if (!options.getMachineFormat()) {
      out.println("Analyzing " + options.getSourceFile() + "...");
    }
  }

  Location getLocation(Source source, int offset) {
    if (!lineInfoMap.containsKey(source)) {
      calculateLineInfo(source);
    }

    if (!lineInfoMap.containsKey(source)) {
      return new Location(-1, -1);
    } else {
      return lineInfoMap.get(source).getLocation(offset);
    }
  }

  private void calculateLineInfo(final Source source) {
    try {
      // TODO(devoncarew): we should get the source and line information when we retrieve the errors

      source.getContents(new Source.ContentReceiver() {
        @Override
        public void accept(CharBuffer contents, long modificationTime) {
          Scanner scanner = new Scanner(source, new CharSequenceReader(contents), null);
          scanner.tokenize();
          lineInfoMap.put(source, new LineInfo(scanner.getLineStarts()));
        }

        @Override
        public void accept(String contents, long modificationTime) {
          Scanner scanner = new Scanner(source, new CharSequenceReader(contents), null);
          scanner.tokenize();
          lineInfoMap.put(source, new LineInfo(scanner.getLineStarts()));
        }
      });
    } catch (Exception e) {
      System.err.println("Source not available for " + source.getFullName());
    }
  }

  private String getMachineCode(ErrorSeverity severity, boolean warningsAreFatal) {
    if (severity.equals(ErrorSeverity.WARNING) && warningsAreFatal) {
      return ErrorSeverity.ERROR.name();
    } else {
      return severity.name();
    }
  }

}
