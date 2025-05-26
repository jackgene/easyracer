import com.sun.management.OperatingSystemMXBean

@main def simple(): Unit =
  println(classOf[OperatingSystemMXBean]) // interface com.sun.management.OperatingSystemMXBean
