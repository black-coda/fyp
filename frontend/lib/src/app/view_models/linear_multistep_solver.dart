import 'dart:developer';
// import 'dart:math';

import 'package:frontend/src/app/view_models/linear_multistep_analysis_method_implementation.dart';
import 'package:frontend/src/module/linear_multistep_solver.dart';
import 'package:frontend/src/utils/constant/constant.dart';
import 'package:frontend/src/utils/devtool/devtool.dart';
import 'package:frontend/src/utils/extension/approximation.dart';

class SolverImplementation implements LinearMultistepSolver {
  @override
  List<double> explicitLinearMultistepMethod({
    required int stepNumber,
    required List<double> alpha,
    required List<double> beta,
    required double Function(double initialValueX, double initialValueY) func,
    required double y0,
    required double x0,
    required double stepSize,
    required int xN,
  }) {
    int N = ((xN - x0) / stepSize).ceil();

    // Initialize the result list with size N and filled with 0s
    List<double> result = List.filled(N, 0, growable: true);

    switch (stepNumber) {
      case 1:
        // Single-step method
        for (int i = 0; i < N; i++) {
          // Calculate the approximate function value at the current point
          double evaluateApproximateFunction = func(x0, y0);
          // Calculate the next value of y
          double y =
              stepSize * (beta.elementAt(0) * evaluateApproximateFunction) -
                  (alpha.elementAt(0) * y0);
          // Store the calculated value in the result list
          result[i] = y;
          // Update x and y for the next iteration
          x0 += stepSize;
          y0 = y;
        }

      case 2:
        List<double> yRKMethod = fourthOrderRungeKuttaExplicitMethod(
            func, y0, x0, stepSize, stepNumber);

        result[0] =
            yRKMethod[0].approximate(6); // Store the first value from RK method

        double y1 =
            result[0]; // Initialize y1 with the first value from RK method
        double x1 = x0 + stepSize; // Initialize x1 for the next point

        // Iterate starting from the second point
        for (int i = 1; i < N; i++) {
          // Calculate the approximate function value at the current point
          double evaluateApproximateFunction = func(x0.approximate(2), y0);

          // Calculate function values at the next step
          double fValuesOfRKResultF1 = func(
              x1.approximate(2), y1.approximate(Constant.approximatedValue));

          // Calculate the new y value using explicit linear multistep method
          double y = stepSize *
                  ((beta.elementAt(0) *
                          evaluateApproximateFunction.approximate(6)) +
                      (beta.elementAt(1) *
                          fValuesOfRKResultF1.approximate(6))) -
              ((alpha.elementAt(1) * y1) + alpha.elementAt(0) * y0);

          // Store the calculated value in the result list
          result[i] = y.approximate(6);

          // Update x0, y0, and y1 for the next iteration
          x0 = x1.approximate(2);
          y0 = y1.approximate(6);
          y1 = y;

          // Update x1 for the next point
          x1 += stepSize;
        }

      default:
        //* Initialize the result list with size N and filled with 0s

        //* add the initial value y (y0) to the result list
        result[0] = y0;

        //* Compute initial values using the fourth-order Runge-Kutta method
        List<double> initialValuesFromRKMethod =
            fourthOrderRungeKuttaExplicitMethod(
                func, y0, x0, stepSize, stepNumber);

        //* approximate the result from RK method to 6dp
        List<double> approximatedYFromRK =
            initialValuesFromRKMethod.map((e) => e.approximate(6)).toList();

        //* add approximated to 6dp values from r-k method to result list in a right order
        result.replaceRange(1, stepNumber - 1, approximatedYFromRK);

        //* get the non-zero value of Y from the result list
        List<double> y = result.sublist(0, stepNumber);

        //* generates values of x based on the step number and initial value x0
        List<double> x = implicitXValueGenerator(x0, stepSize, stepNumber)
            .map((e) => e.approximate(2))
            .toList();

        //* f values from f1 => f(stepNumber - 1)
        List<double> fValues = [];

        //* initial values of alpha and beta
        double betaF = 0;
        double alphaY = 0;

        //* summation using the general lmm formulae
        for (var i = stepNumber; i <= N; i++) {
          /// * calculate the values of f0,f1 ... f(stepNumber -1), then add it to the [fValues]
          for (var j = 0; j < stepNumber; j++) {
            double xj = x[j];
            double yj = y[j];

            fValues.add(func(xj, yj));
          }

          //* Approximate fValues to 6dp
          fValues = fValues
              .map((e) => e.approximate(Constant.approximatedValue))
              .toList();
          //! Using the formula

          //* calculate summation beta * fi
          for (var k = 0; k < stepNumber; k++) {
            betaF += beta[k] * fValues[k];
          }

          //* calculate summation alpha*y
          for (var l = 0; l < stepNumber; l++) {
            alphaY += alpha[l] * y[l];
          }

          //? Calculate the new y => h[beta*f] - alpha*y
          double nextValueOfY =
              (stepSize * betaF.approximate(Constant.approximatedValue)) -
                  alphaY.approximate(6);

          //? add the next value of y calculated to the list of y
          y.add(nextValueOfY.approximate(Constant.approximatedValue));

          //? add the next value of y calculated to the result list
          result[i] = nextValueOfY.approximate(Constant.approximatedValue);

          //? updating values

          //* update values of x
          for (var m = 0; m < x.length; m++) {
            x[m] += stepSize;
          }

          //* approximate the values of x to 1dp
          x = x.map((e) => e.approximate(1)).toList();

          //* Update values of y by removing the first value in the list
          y.removeAt(0);

          //* reset the values of betaF and alpha Y to 0
          betaF = 0;
          alphaY = 0;

          //* reset the fValues to an empty list
          fValues = [];
        }
    }

    log(result.toString());
    return result;
  }

  @override
  List<double> implicitLinearizationMethod({
    required int stepNumber,
    required List<double> alpha,
    required List<double> beta,
    required double Function(double initialValueX, double initialValueY) func,
    required double y0,
    required double x0,
    required double stepSize,
    required int N,
    required int a,
    required int b,
  }) {
    List<double> result = List.filled(N, 0, growable: true);
    //* add initial value to result i.e y0
    result[0] = y0;

    List<double> valuesFromRKMethod =
        fourthOrderRungeKuttaExplicitMethod(func, y0, x0, stepSize, stepNumber);

    //* approximate the result from RK method to 6dp
    List<double> approximatedYFromRK =
        valuesFromRKMethod.map((e) => e.approximate(6)).toList();

    //* add approximated to 6dp values from r-k method to result list in a right order
    result.replaceRange(1, stepNumber - 1, approximatedYFromRK);

//* get the non-zero value of Y from the result list
    List<double> y = result.sublist(0, stepNumber);
    log(y.toString(), name: "y1");

    //* generates values of x based on the step number and initial value x0
    List<double> x = implicitXValueGenerator(x0, stepSize, stepNumber - 1)
        .map((e) => e.approximate(2))
        .toList();

    log(x.toString(), name: "x1");

    //* f values from f1 => f(stepNumber - 1)
    List<double> fValues = [];

    //* initial values of alpha and beta
    double betaF = 0;
    double alphaY = 0;

    //* summation using the general lmm formulae
    for (var i = stepNumber; i <= 3; i++) {
      /// * calculate the values of f0,f1 ... f(stepNumber -1), then add it to the [fValues]
      for (var j = 0; j < stepNumber; j++) {
        double xj = x[j];
        double yj = y[j];

        fValues.add(func(xj, yj));
      }

      //* Approximate fValues to 6dp
      fValues = fValues.map((e) => e.approximate(6)).toList();
      log(fValues.toString(), name: "fValues");
      //! Using the formula

      //* calculate summation beta * fi
      for (var k = 0; k < stepNumber - 1; k++) {
        betaF += beta[k] * fValues[k];
      }

      // //* calculate summation alpha*y
      for (var l = 0; l < stepNumber - 1; l++) {
        alphaY += alpha[l] * y[l];
      }

      final denominator = alpha.last - stepSize * beta.last * a * x[i];
      log(denominator.toString(), name: "denominator");
      final numerator = stepSize * beta.last * b + (stepSize * betaF) - alphaY;
      log(numerator.toString(), name: "numerator");
      final nextValueOfY = numerator / denominator;
      log(nextValueOfY.toString(), name: "next value of y");

      // //? Calculate the new y => h[beta*f] - alpha*y
      // double nextValueOfY =
      //     (stepSize * betaF.approximate(6)) - alphaY.approximate(6);

      // //? add the next value of y calculated to the list of y
      // y.add(nextValueOfY.approximate(6));

      // //? add the next value of y calculated to the result list
      // result[i] = nextValueOfY.approximate(6);

      // //? updating values

      // //* update values of x
      // for (var m = 0; m < x.length; m++) {
      //   x[m] += stepSize;
      // }

      // //* approximate the values of x to 1dp
      // x = x.map((e) => e.approximate(1)).toList();

      // //* Update values of y by removing the first value in the list
      // y.removeAt(0);

      // //* reset the values of betaF and alpha Y to 0
      // betaF = 0;
      // alphaY = 0;

      // //* reset the fValues to an empty list
      // fValues = [];
    }

    log(result.toString(), name: "result");
    return result;
  }

  List<double> fourthOrderRungeKuttaExplicitMethod(
    Function func,
    double y0,
    double x0,
    double stepSize,
    int N,
  ) {
    // Initialize variables
    double y = y0;
    double x = x0;
    List<double> result = List.filled(N - 1, 0);

    // Perform RK method
    for (int i = 0; i < N - 1; i++) {
      x = x.approximate(6);
      final k1 = func(x, y);
      final k2 = func(x + stepSize * 0.5, y + k1 * stepSize * 0.5);
      final k3 = func(x + stepSize * 0.5, y + k2 * stepSize * 0.5);
      final k4 = func(x + stepSize, y + k3 * stepSize);

      final calculateNextValueOfY =
          y + (stepSize / 6) * (k1 + 2 * k2 + 2 * k3 + k4);

      result[i] = calculateNextValueOfY.approximate(6);

      y = calculateNextValueOfY.approximate(6);
      x += stepSize;
    }

    return result;
  }

  List<double> implicitXValueGenerator(double x0, double stepSize, int N,
      {int decimalPlaces = 1, int implicit = 0}) {
    String firstValueOfX = x0.toString();
    List<String> xValues = [];
    xValues.add(firstValueOfX);
    for (int n = 1; n <= N + 1; n++) {
      double x = x0 + n * stepSize;
      xValues.add(x.toStringAsFixed(decimalPlaces));
    }
    return xValues.map((e) => double.parse(e)).toList();
  }

  List<double> fourthOrderRungeKuttaMethod(
      Function func, double y0, double x0, double stepSize, int N,
      [int implicit = 0]) {
    // Initialize variables
    double y = y0;
    double x = x0.approximate(1);

    List<double> result = List.filled(N - implicit, 0);

    // Perform RK method
    for (int i = 0; i < N - implicit; i++) {
      x = x.approximate(6);
      final double k1 = func(x, y);
      final double k2 =
          func(x + stepSize * 0.5, y + k1.approximate(6) * stepSize * 0.5);
      final double k3 =
          func(x + stepSize * 0.5, y + k2.approximate(6) * stepSize * 0.5);
      final double k4 = func(x + stepSize, y + k3.approximate(6) * stepSize);

      final calculateNextValueOfY =
          y + (stepSize / 6) * (k1 + 2 * k2 + 2 * k3 + k4);

      result[i] = calculateNextValueOfY.approximate(6);

      y = calculateNextValueOfY.approximate(6);
      x += stepSize;
    }

    return result;
  }

  @override
  List<double> implicitLinearMultistepMethodWithPredictorCorrectorMethod({
    required int predictorStepNumber,
    required List<double> correctorAlpha,
    required List<double> correctorBeta,
    required List<double> predictorAlpha,
    required List<double> predictorBeta,
    required double Function(double initialValueX, double initialValueY) func,
    required double y0,
    required double x0,
    required double stepSize,
    required int xN,
    required int correctorStepNumber,
  }) {
    int N = ((xN - x0) / stepSize).ceil();
    final predictorOrder = AnalysisImplementation(
            kSteps: predictorStepNumber,
            alpha: predictorAlpha,
            beta: predictorBeta)
        .orderAndErrorConstant()
        .$1;
    log(predictorOrder.toString());

    final correctorOrder = AnalysisImplementation(
            kSteps: correctorStepNumber,
            alpha: correctorAlpha,
            beta: correctorBeta)
        .orderAndErrorConstant()
        .$1;

    log(correctorOrder.toString());

    if (predictorOrder != correctorOrder) {
      throw const FormatException(
          "The predictor-corrector scheme must have the same order");
    }
    List<double> result = List.filled(N, 0, growable: true);

    /// [PECE] Algorithm will be implemented Prediction Evaluation Correction Evaluation
    ///
    /// Starter values from runge-kutta method
    ///

    //! Predictor
    List<double> starterY = explicitLinearMultistepForImplicitMethod(
      stepNumber: predictorStepNumber,
      alpha: predictorAlpha,
      beta: predictorBeta,
      func: func,
      y0: y0,
      x0: x0,
      stepSize: stepSize,
      N: predictorStepNumber,
    );

    /// add the starter values from runge-kutta to the list of [result]

    result.replaceRange(0, predictorStepNumber - 1, starterY);

    // get the y values

    List<double> y = result.sublist(0, predictorStepNumber + 1);

    //x value
    List<double> x = implicitXValueGenerator(
        x0, stepSize, predictorStepNumber - 1,
        decimalPlaces: 2);

    List<double> fValues = [];

    //* initial values of alpha and beta
    double betaF = 0;
    double alphaY = 0;

    //* method summation

    for (var i = predictorStepNumber; i <= N; i++) {
      /// * calculate the values of f0,f1 ... f(stepNumber), then add it to the [fValues]
      for (var j = 0; j <= predictorStepNumber; j++) {
        double xj = x[j];
        double yj = y[j];
        fValues.add(func(xj, yj));
      }

      // remove first element in the list of f
      // fValues.removeAt(0);

      for (var k = 0; k <= correctorStepNumber; k++) {
        betaF += correctorBeta[k] * fValues[k + 1];
      }

      //* calculate summation alpha*y
      for (var l = 0; l <= correctorStepNumber - 1; l++) {
        alphaY += correctorAlpha[l] * y[l + 1];
      }

      //? Calculate the new y => h[beta*f] - alpha*y
      double nextValueOfY = (stepSize * betaF) - alphaY;
      nextValueOfY = nextValueOfY.approximate(Constant.approximatedValue);

      result[i] = nextValueOfY;

      log(y.toString());
      // remove the first element
      y.removeAt(0);

      log(y.toString());

      y.removeLast();
      y.add(nextValueOfY);

      //? updating values

      //* Predict next y

      //* reset the values of betaF and alpha Y to 0
      betaF = 0;
      alphaY = 0;

      //* reset the fValues to an empty list
      fValues = [];

      //* update values of x
      for (var m = 0; m < x.length; m++) {
        x[m] += stepSize;
      }
      x = x.map((e) => e.approximate(2)).toList();

      log("carry me ${x.toString()}");
      log(y.toString());
      double yNewPredicted = explicitYPredictor(
          alpha: predictorAlpha,
          beta: predictorBeta,
          func: func,
          y: y,
          xStarter: x,
          stepSize: stepSize,
          stepNumber: predictorStepNumber,
          N: 1);
      log("yNewpredicted: $yNewPredicted");
      y.add(yNewPredicted);
      x.add(x.last + stepSize);
      x.log();
    }
    result.removeLast();
    return result;
  }

  // predictor for next value of y

  double explicitYPredictor(
      {required List<double> alpha,
      required List<double> beta,
      required double Function(double initialValueX, double initialValueY) func,
      required List<double> y,
      required List<double> xStarter,
      required double stepSize,
      required int stepNumber,
      int N = 1}) {
    List<double> fValues = [];
    double nextValueOfY = 0;

    //* initial values of alpha and beta
    double betaF = 0;
    double alphaY = 0;

    List<double> x = xStarter;
    x.removeLast();

    //* summation using the general lmm formulae
    for (var i = 0; i <= 0; i++) {
      /// * calculate the values of f0,f1 ... f(stepNumber -1), then add it to the [fValues]
      for (var j = 0; j < stepNumber; j++) {
        double xj = x[j];
        double yj = y[j];

        fValues.add(func(xj, yj).approximate(6));
      }

      //* Approximate fValues to 6dp
      fValues = fValues.map((e) => e.approximate(6)).toList();
      //! Using the formula

      //* calculate summation beta * fi
      for (var k = 0; k < stepNumber; k++) {
        betaF += beta[k] * fValues[k];
      }

      //* calculate summation alpha*y
      for (var l = 0; l < stepNumber; l++) {
        alphaY += alpha[l] * y[l];
      }

      //? Calculate the new y => h[beta*f] - alpha*y
      nextValueOfY = (stepSize * betaF.approximate(6)) - alphaY.approximate(6);
    }

    // //* reset the values of betaF and alpha Y to 0
    // betaF = 0;
    // alphaY = 0;

    // //* reset the fValues to an empty list
    // fValues = [];

    return nextValueOfY;
  }

  @override
  List<double> explicitLinearMultistepForImplicitMethod(
      {required int stepNumber,
      required List<double> alpha,
      required List<double> beta,
      required double Function(double initialValueX, double initialValueY) func,
      required double y0,
      required double x0,
      required double stepSize,
      required int N}) {
    List<double> result = List.filled(N, 0, growable: true);

    switch (stepNumber) {
      case 1:
        // Single-step method
        for (int i = 0; i < N; i++) {
          // Calculate the approximate function value at the current point
          double evaluateApproximateFunction = func(x0, y0);
          // Calculate the next value of y
          double y =
              stepSize * (beta.elementAt(0) * evaluateApproximateFunction) -
                  (alpha.elementAt(0) * y0);
          // Store the calculated value in the result list
          result[i] = y;
          // Update x and y for the next iteration
          x0 += stepSize;
          y0 = y;
        }

      case 2:
        List<double> yRKMethod = fourthOrderRungeKuttaExplicitMethod(
            func, y0, x0, stepSize, stepNumber);

        result[0] = yRKMethod[0].approximate(
            Constant.approximatedValue); // Store the first value from RK method

        double y1 =
            result[0]; // Initialize y1 with the first value from RK method
        double x1 = x0 + stepSize; // Initialize x1 for the next point

        // Iterate starting from the second point
        for (int i = 1; i < N; i++) {
          // Calculate the approximate function value at the current point
          double evaluateApproximateFunction = func(x0.approximate(2), y0);

          // Calculate function values at the next step
          double fValuesOfRKResultF1 = func(
              x1.approximate(2), y1.approximate(Constant.approximatedValue));

          // Calculate the new y value using explicit linear multistep method
          double y = stepSize *
                  ((beta.elementAt(0) *
                          evaluateApproximateFunction
                              .approximate(Constant.approximatedValue)) +
                      (beta.elementAt(1) *
                          fValuesOfRKResultF1
                              .approximate(Constant.approximatedValue))) -
              ((alpha.elementAt(1) * y1) + alpha.elementAt(0) * y0);

          // Store the calculated value in the result list
          result[i] = y.approximate(Constant.approximatedValue);

          // Update x0, y0, and y1 for the next iteration
          x0 = x1.approximate(2);
          y0 = y1.approximate(Constant.approximatedValue);
          y1 = y;

          // Update x1 for the next point
          x1 += stepSize;
        }

      default:
        //* Initialize the result list with size N and filled with 0s

        //* add the initial value y (y0) to the result list
        result[0] = y0;

        //* Compute initial values using the fourth-order Runge-Kutta method
        List<double> initialValuesFromRKMethod =
            fourthOrderRungeKuttaExplicitMethod(
                func, y0, x0, stepSize, stepNumber);

        //* approximate the result from RK method to 6dp
        List<double> approximatedYFromRK = initialValuesFromRKMethod
            .map((e) => e.approximate(Constant.approximatedValue))
            .toList();

        //* add approximated to 6dp values from r-k method to result list in a right order
        result.replaceRange(1, stepNumber - 1, approximatedYFromRK);

        //* get the non-zero value of Y from the result list
        List<double> y = result.sublist(0, stepNumber);

        //* generates values of x based on the step number and initial value x0
        List<double> x = implicitXValueGenerator(x0, stepSize, stepNumber)
            .map((e) => e.approximate(2))
            .toList();

        //* f values from f1 => f(stepNumber - 1)
        List<double> fValues = [];

        //* initial values of alpha and beta
        double betaF = 0;
        double alphaY = 0;

        //* summation using the general lmm formulae
        for (var i = stepNumber; i <= N; i++) {
          /// * calculate the values of f0,f1 ... f(stepNumber -1), then add it to the [fValues]
          for (var j = 0; j < stepNumber; j++) {
            double xj = x[j];
            double yj = y[j];

            fValues.add(func(xj, yj));
          }

          //* Approximate fValues to 6dp
          fValues = fValues
              .map((e) => e.approximate(Constant.approximatedValue))
              .toList();
          //! Using the formula

          //* calculate summation beta * fi
          for (var k = 0; k < stepNumber; k++) {
            betaF += beta[k] * fValues[k];
          }

          //* calculate summation alpha*y
          for (var l = 0; l < stepNumber; l++) {
            alphaY += alpha[l] * y[l];
          }

          //? Calculate the new y => h[beta*f] - alpha*y
          double nextValueOfY =
              (stepSize * betaF.approximate(Constant.approximatedValue)) -
                  alphaY.approximate(Constant.approximatedValue);

          //? add the next value of y calculated to the list of y
          y.add(nextValueOfY.approximate(Constant.approximatedValue));

          //? add the next value of y calculated to the result list
          result[i] = nextValueOfY.approximate(Constant.approximatedValue);

          //? updating values

          //* update values of x
          for (var m = 0; m < x.length; m++) {
            x[m] += stepSize;
          }

          //* approximate the values of x to 1dp
          x = x.map((e) => e.approximate(1)).toList();

          //* Update values of y by removing the first value in the list
          y.removeAt(0);

          //* reset the values of betaF and alpha Y to 0
          betaF = 0;
          alphaY = 0;

          //* reset the fValues to an empty list
          fValues = [];
        }
    }

    log(result.toString());
    return result;
  }
}
