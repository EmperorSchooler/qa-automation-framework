export const TestData = {
  users: {
    standard:    'standard_user',
    locked:      'locked_out_user',
    problem:     'problem_user',
    performance: 'performance_glitch_user',
  },
  passwords: {
    valid:   'secret_sauce',
    invalid: 'wrong_password_123',
  },
  api: {
    validLogin: {
      email:    'eve.holt@reqres.in',
      password: 'cityslicka',
    },
    newUser: {
      name: 'Demitre Schooler',
      job:  'Senior QA Automation Engineer',
    },
    updatedUser: {
      name: 'Demitre Schooler',
      job:  'Senior SDET',
    },
  },
  timeouts: { short: 5000, medium: 15000, long: 30000 },
} as const;
