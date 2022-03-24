import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';
import 'package:pinball/game/game.dart';
import 'package:pinball/gen/assets.gen.dart';

const _leftFlipperKeys = [
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.keyA,
];

const _rightFlipperKeys = [
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.keyD,
];

/// {@template flipper}
/// A bat, typically found in pairs at the bottom of the board.
///
/// [Flipper] can be controlled by the player in an arc motion.
/// {@endtemplate flipper}
class Flipper extends BodyComponent with KeyboardHandler, InitialPosition {
  /// {@macro flipper}
  Flipper({
    required this.side,
  }) : _keys = side.isLeft ? _leftFlipperKeys : _rightFlipperKeys;

  /// The size of the [Flipper].
  static final size = Vector2(12, 2.8);

  /// The speed required to move the [Flipper] to its highest position.
  ///
  /// The higher the value, the faster the [Flipper] will move.
  static const double _speed = 60;

  /// Whether the [Flipper] is on the left or right side of the board.
  ///
  /// A [Flipper] with [BoardSide.left] has a counter-clockwise arc motion,
  /// whereas a [Flipper] with [BoardSide.right] has a clockwise arc motion.
  final BoardSide side;

  /// The [LogicalKeyboardKey]s that will control the [Flipper].
  ///
  /// [onKeyEvent] method listens to when one of these keys is pressed.
  final List<LogicalKeyboardKey> _keys;

  /// Applies downward linear velocity to the [Flipper], moving it to its
  /// resting position.
  void _moveDown() {
    body.linearVelocity = Vector2(0, -_speed);
  }

  /// Applies upward linear velocity to the [Flipper], moving it to its highest
  /// position.
  void _moveUp() {
    body.linearVelocity = Vector2(0, _speed);
  }

  /// Loads the sprite that renders with the [Flipper].
  Future<void> _loadSprite() async {
    final sprite = await gameRef.loadSprite(
      Assets.images.components.flipper.path,
    );
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
    );

    if (side.isRight) {
      spriteComponent.flipHorizontally();
    }

    await add(spriteComponent);
  }

  /// Anchors the [Flipper] to the [RevoluteJoint] that controls its arc motion.
  Future<void> _anchorToJoint() async {
    final anchor = _FlipperAnchor(flipper: this);
    await add(anchor);

    final jointDef = _FlipperAnchorRevoluteJointDef(
      flipper: this,
      anchor: anchor,
    );
    final joint = _FlipperJoint(jointDef)..create(world);

    // FIXME(erickzanardo): when mounted the initial position is not fully
    // reached.
    unawaited(
      mounted.whenComplete(joint.unlock),
    );
  }

  List<FixtureDef> _createFixtureDefs() {
    final fixturesDef = <FixtureDef>[];
    final direction = side.direction;

    final bigCircleShape = CircleShape()..radius = 1.75;
    bigCircleShape.position.setValues(
      ((size.x / 2) * direction) + (bigCircleShape.radius * -direction),
      0,
    );
    final bigCircleFixtureDef = FixtureDef(bigCircleShape);
    fixturesDef.add(bigCircleFixtureDef);

    final smallCircleShape = CircleShape()..radius = 0.9;
    smallCircleShape.position.setValues(
      ((size.x / 2) * -direction) + (smallCircleShape.radius * direction),
      0,
    );
    final smallCircleFixtureDef = FixtureDef(smallCircleShape);
    fixturesDef.add(smallCircleFixtureDef);

    final trapeziumVertices = side.isLeft
        ? [
            Vector2(bigCircleShape.position.x, bigCircleShape.radius),
            Vector2(smallCircleShape.position.x, smallCircleShape.radius),
            Vector2(smallCircleShape.position.x, -smallCircleShape.radius),
            Vector2(bigCircleShape.position.x, -bigCircleShape.radius),
          ]
        : [
            Vector2(smallCircleShape.position.x, smallCircleShape.radius),
            Vector2(bigCircleShape.position.x, bigCircleShape.radius),
            Vector2(bigCircleShape.position.x, -bigCircleShape.radius),
            Vector2(smallCircleShape.position.x, -smallCircleShape.radius),
          ];
    final trapezium = PolygonShape()..set(trapeziumVertices);
    final trapeziumFixtureDef = FixtureDef(trapezium)
      ..density = 50.0 // TODO(alestiago): Use a proper density.
      ..friction = .1; // TODO(alestiago): Use a proper friction.
    fixturesDef.add(trapeziumFixtureDef);

    return fixturesDef;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    await Future.wait([
      _loadSprite(),
      _anchorToJoint(),
    ]);
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..position = initialPosition
      ..gravityScale = 0
      ..type = BodyType.dynamic;
    final body = world.createBody(bodyDef);
    _createFixtureDefs().forEach(body.createFixture);

    return body;
  }

  @override
  bool onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (!_keys.contains(event.logicalKey)) return true;

    if (event is RawKeyDownEvent) {
      _moveUp();
    } else if (event is RawKeyUpEvent) {
      _moveDown();
    }

    return false;
  }
}

/// {@template flipper_anchor}
/// [JointAnchor] positioned at the end of a [Flipper].
///
/// The end of a [Flipper] depends on its [Flipper.side].
/// {@endtemplate}
class _FlipperAnchor extends JointAnchor {
  /// {@macro flipper_anchor}
  _FlipperAnchor({
    required Flipper flipper,
  }) {
    initialPosition = Vector2(
      flipper.body.position.x + ((Flipper.size.x * flipper.side.direction) / 2),
      flipper.body.position.y,
    );
  }
}

/// {@template flipper_anchor_revolute_joint_def}
/// Hinges one end of [Flipper] to a [_FlipperAnchor] to achieve an arc motion.
/// {@endtemplate}
class _FlipperAnchorRevoluteJointDef extends RevoluteJointDef {
  /// {@macro flipper_anchor_revolute_joint_def}
  _FlipperAnchorRevoluteJointDef({
    required Flipper flipper,
    required _FlipperAnchor anchor,
  }) : side = flipper.side {
    initialize(
      flipper.body,
      anchor.body,
      anchor.body.position,
    );

    enableLimit = true;
    final angle = (_sweepingAngle * -side.direction) / 2;
    lowerAngle = upperAngle = angle;
  }

  /// The total angle of the arc motion.
  static const _sweepingAngle = math.pi / 3.5;

  final BoardSide side;
}

class _FlipperJoint extends RevoluteJoint {
  _FlipperJoint(_FlipperAnchorRevoluteJointDef def)
      : side = def.side,
        super(def);

  final BoardSide side;

  // TODO(alestiago): Remove once Forge2D supports custom joints.
  void create(World world) {
    world.joints.add(this);
    bodyA.joints.add(this);
    bodyB.joints.add(this);
  }

  /// Unlocks the [Flipper] from its resting position.
  ///
  /// The [Flipper] is locked when initialized in order to force it to be at
  /// its resting position.
  void unlock() {
    setLimits(
      lowerLimit * side.direction,
      -upperLimit * side.direction,
    );
  }
}
