A triggered effect can have interruptible, it gets removed if the character or source is subject to an interrupt action.
A triggered effect can have valid_if callback, which if returns false, means that the effect is cancelled.

PRE_EFFECT - before the triggering actions. Processes its own Pre_effects after itself. Mainly for pre-emptive counter attacks
IMMEDIATE - after the triggering actions. Processes its own Pre_effects after itself. Mainly for immediate physics chains, like oil -> fire
POST_EFFECT_FAST - mainly for automatic responses
POST_EFFECT_SLOW - mainly for character responses.
END_OF_TREE - Exists the current tree and adds a response at the end of the trunk.
