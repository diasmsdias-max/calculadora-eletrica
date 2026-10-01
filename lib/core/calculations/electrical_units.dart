abstract final class ElectricalUnits {
  static const double wattsPerKilowatt = 1000;
  static const double wattsPerCv = 735.49875;
  static const double wattsPerHp = 745.699872;

  static double kwToW(double kw) => kw * wattsPerKilowatt;
  static double wToKw(double watts) => watts / wattsPerKilowatt;
  static double cvToKw(double cv) => cv * wattsPerCv / wattsPerKilowatt;
  static double hpToKw(double hp) => hp * wattsPerHp / wattsPerKilowatt;
}
