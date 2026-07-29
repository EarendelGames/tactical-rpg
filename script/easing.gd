class_name Easing

static var k: float = 1.05 # Scale this up for sharper easing, or keep at 1.1 for subtle easing

static func in_out_faint(t: float) -> float:
	# Guard against division by zero at the absolute boundaries
	if t <= 0.0: return 0.0
	if t >= 1.0: return 1.0
	var tk = pow(t, k)
	return tk / (tk + pow(1.0 - t, k))
