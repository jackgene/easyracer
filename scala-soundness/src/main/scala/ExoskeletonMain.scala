import com.sun.management.OperatingSystemMXBean
import soundness.*
import soundness.executives.direct
import soundness.parameterInterpretation.posix
import soundness.unhandledErrors.stackTrace

@main def exoskeleton(): Unit = application(Nil):
  println(classOf[OperatingSystemMXBean])
  Exit.Ok
